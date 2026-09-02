# frozen_string_literal: true

require_relative "../../test_helper"

require "action_controller"

class ReActionView::DevToolsMarkupTest < Minitest::Spec
  RAILS_ROOT = "/app"
  LAYOUT = "/app/app/views/layouts/application.html.erb"
  MAILER_LAYOUT = "/app/app/views/layouts/mailer.html.erb"
  VIEW = "/app/app/views/users/show.html.erb"

  SOURCE = %(<html><head></head><body></body></html>)

  DISMISS_HINT = "data-herb-dismiss-hint"

  before do
    @previous_debug_mode = ReActionView.config.debug_mode
  end

  after do
    ReActionView.config.debug_mode = @previous_debug_mode
    ReActionView.config.validation_mode = nil
  end

  def compile(identifier: LAYOUT, virtual_path: "layouts/application")
    template = ActionView::Template.new(
      SOURCE,
      identifier,
      ReActionView::Template::Handlers::Herb,
      virtual_path: virtual_path,
      format: :html,
      locals: []
    )

    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      ReActionView::Template::Handlers::Herb.call(template, SOURCE)
    end
  end

  test "does not emit the dismiss hint when debug mode is off" do
    ReActionView.config.debug_mode = false
    ReActionView.config.validation_mode = :overlay

    refute_includes compile, DISMISS_HINT
  end

  test "does not emit the dismiss hint in mailer layouts when debug mode is off" do
    ReActionView.config.debug_mode = false
    ReActionView.config.validation_mode = :overlay

    refute_includes compile(identifier: MAILER_LAYOUT, virtual_path: "layouts/mailer"), DISMISS_HINT
  end

  test "emits nothing at all into the head when debug mode is off" do
    ReActionView.config.debug_mode = false
    ReActionView.config.validation_mode = :overlay

    compiled = compile

    refute_includes compiled, "herb-debug-mode"
    refute_includes compiled, "reactionview-dev-tools"
    refute_includes compiled, DISMISS_HINT
  end

  test "emits the dismiss hint when debug mode is on and validation mode is :overlay" do
    ReActionView.config.debug_mode = true
    ReActionView.config.validation_mode = :overlay

    compiled = compile

    assert_includes compiled, DISMISS_HINT
    assert_includes compiled, "herb-debug-mode"
  end

  test "does not emit the dismiss hint when validation mode is not :overlay" do
    ReActionView.config.debug_mode = true
    ReActionView.config.validation_mode = :none

    compiled = compile

    refute_includes compiled, DISMISS_HINT
    assert_includes compiled, "herb-debug-mode"
  end

  test "emits nothing for templates that are not layouts" do
    ReActionView.config.debug_mode = true
    ReActionView.config.validation_mode = :overlay

    compiled = compile(identifier: VIEW, virtual_path: "users/show")

    refute_includes compiled, DISMISS_HINT
    refute_includes compiled, "herb-debug-mode"
  end

  REQUEST = Struct.new(:user_agent)

  class RenderContext
    attr_reader :output_buffer

    attr_reader :request

    def initialize(request)
      @request = request
      @output_buffer = ActionView::OutputBuffer.new
    end

    def method_missing(*) = ""

    def respond_to_missing?(*) = true
  end

  def render(compiled, user_agent)
    context = RenderContext.new(REQUEST.new(user_agent))
    context.instance_eval(compiled)
    context.output_buffer.to_s
  end

  test "compiles a render-time condition when debug mode is a callable" do
    ReActionView.config.debug_mode = ->(_request) { true }

    assert_includes compile, "debug_mode_for_request?"
  end

  test "a callable debug mode decides per request from one compiled template" do
    ReActionView.config.debug_mode = ->(request) { !request.user_agent.to_s.include?("Hotwire Native") }

    compiled = compile

    assert_includes render(compiled, "Mozilla/5.0"), "herb-debug-mode"
    refute_includes render(compiled, "MyApp Hotwire Native iOS"), "herb-debug-mode"
  end

  test "a callable returning a non-boolean is evaluated for truthiness" do
    ReActionView.config.debug_mode = ->(request) { request.user_agent.presence }

    compiled = compile

    assert_includes render(compiled, "Mozilla/5.0"), "herb-debug-mode"
    refute_includes render(compiled, ""), "herb-debug-mode"
  end

  test "a callable is not invoked when there is no request" do
    ReActionView.config.debug_mode = ->(request) { request.user_agent.include?("nope") }

    refute ReActionView.config.debug_mode_for_request?(nil)
  end

  test "debug_mode_enabled? assumes enabled for a callable so boot-time hooks still install" do
    ReActionView.config.debug_mode = ->(_request) { false }

    assert ReActionView.config.debug_mode_enabled?
  end

  test "a non-callable truthy value is evaluated for truthiness" do
    ReActionView.config.debug_mode = "yes"

    assert ReActionView.config.debug_mode_enabled?
    assert_includes compile, "herb-debug-mode"
  end

  test "non-callable values still compile a static tag with no render-time condition" do
    ReActionView.config.debug_mode = true

    compiled = compile

    assert_includes compiled, "herb-debug-mode"
    refute_includes compiled, "debug_mode_for_request?"
  end

  test "debug_mode_for_request? falls back to the static value for non-callables" do
    ReActionView.config.debug_mode = true
    assert ReActionView.config.debug_mode_for_request?(nil)

    ReActionView.config.debug_mode = false
    refute ReActionView.config.debug_mode_for_request?(nil)
  end
end

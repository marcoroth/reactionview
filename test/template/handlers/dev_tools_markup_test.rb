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
    @previous_validation_mode = ReActionView.config.validation_mode

    ReActionView.config.intercept_erb = true
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
end

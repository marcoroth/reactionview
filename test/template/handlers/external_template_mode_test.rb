# frozen_string_literal: true

require_relative "../../test_helper"

class ReActionView::ExternalTemplateModeTest < Minitest::Spec
  RAILS_ROOT = "/app"
  EXTERNAL = "/gems/devise-4.9.4/app/views/devise/sessions/new.html.erb"
  FRAMEWORK = "/gems/actionpack-8.1.2/lib/action_dispatch/middleware/templates/rescues/routing_error.html.erb"
  LOCAL = "/app/app/views/users/show.html.erb"

  INVALID = %(<p><h2>I am invalid</h2></p>)
  VALID = %(<div id="x"><h1>Hi <%= @n %></h1></div>)

  before do
    @previous_mode = ReActionView.config.external_template_mode
    @previous_logger = Rails.logger

    ReActionView.config.debug_mode = false
    ReActionView.config.intercept_erb = true

    @log = StringIO.new
    Rails.logger = Logger.new(@log)
  end

  after do
    ReActionView.config.external_template_mode = @previous_mode
    Rails.logger = @previous_logger
  end

  def build(source, identifier)
    ActionView::Template.new(
      source,
      identifier,
      ReActionView::Template::Handlers::ERB,
      virtual_path: "users/show",
      format: :html,
      locals: []
    )
  end

  def compile(source, identifier)
    template = build(source, identifier)

    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      template.handler.call(template, source)
    end
  end

  test "defaults to :fallback" do
    assert_equal :fallback, ReActionView::Config.new.external_template_mode
  end

  test "returns the configured mode" do
    config = ReActionView::Config.new
    config.external_template_mode = :skip

    assert_equal :skip, config.external_template_mode
  end

  test "nil resets to the default" do
    config = ReActionView::Config.new
    config.external_template_mode = :skip
    config.external_template_mode = nil

    assert_equal :fallback, config.external_template_mode
  end

  test "rejects an unknown mode" do
    config = ReActionView::Config.new

    error = assert_raises(ArgumentError) do
      config.external_template_mode = :warm
    end

    assert_includes error.message, "must be one of :fallback, :skip, or :compile"
    assert_includes error.message, ":warm"
  end

  test ":fallback compiles external templates that Herb can handle" do
    ReActionView.config.external_template_mode = :fallback

    compiled = compile(VALID, EXTERNAL)

    refute_equal ActionView::Template::Handlers::ERB.new.call(build(VALID, EXTERNAL), VALID), compiled
    assert_empty @log.string
  end

  test ":fallback falls back to ERB and logs when Herb cannot compile an external template" do
    ReActionView.config.external_template_mode = :fallback

    compiled = compile(INVALID, EXTERNAL)

    assert_equal ActionView::Template::Handlers::ERB.new.call(build(INVALID, EXTERNAL), INVALID), compiled
    assert_includes @log.string, "[ReActionView]"
    assert_includes @log.string, EXTERNAL
    assert_includes @log.string, "falling back to"
  end

  test ":skip never compiles external templates" do
    ReActionView.config.external_template_mode = :skip

    compiled = compile(VALID, EXTERNAL)

    assert_equal ActionView::Template::Handlers::ERB.new.call(build(VALID, EXTERNAL), VALID), compiled
    assert_empty @log.string
  end

  test ":compile lets external template failures raise" do
    ReActionView.config.external_template_mode = :compile
    ReActionView.config.validation_mode = :raise

    assert_raises(Herb::Engine::CompilationError) do
      compile(INVALID, EXTERNAL)
    end
  ensure
    ReActionView.config.validation_mode = nil
  end

  test "never compiles a template Rails renders its own errors from" do
    ReActionView.config.external_template_mode = :compile

    compiled = compile(VALID, FRAMEWORK)

    assert_equal ActionView::Template::Handlers::ERB.new.call(build(VALID, FRAMEWORK), VALID), compiled
    assert_empty @log.string
  end

  test "leaves it to Rails even when Herb could not have compiled it anyway" do
    ReActionView.config.external_template_mode = :compile
    ReActionView.config.validation_mode = :raise

    compiled = compile(INVALID, FRAMEWORK)

    assert_equal ActionView::Template::Handlers::ERB.new.call(build(INVALID, FRAMEWORK), INVALID), compiled
  ensure
    ReActionView.config.validation_mode = nil
  end

  test ":compile applies the configured validation mode to external templates" do
    ReActionView.config.external_template_mode = :compile
    ReActionView.config.validation_mode = :overlay

    compiled = compile(INVALID, EXTERNAL)

    assert_includes compiled, "data-herb-validation-error"
    assert_empty @log.string
  ensure
    ReActionView.config.validation_mode = nil
  end

  test "external .herb templates use the configured validation mode" do
    ReActionView.config.external_template_mode = :fallback
    ReActionView.config.validation_mode = :overlay

    template = ActionView::Template.new(
      INVALID,
      "/gems/some_gem/app/views/x.html.herb",
      ReActionView::Template::Handlers::Herb,
      virtual_path: "x",
      format: :html,
      locals: []
    )

    compiled = Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      ReActionView::Template::Handlers::Herb.call(template, INVALID)
    end

    assert_includes compiled, "data-herb-validation-error"
  ensure
    ReActionView.config.validation_mode = nil
  end

  test "local template failures always raise, whatever the mode" do
    ReActionView.config.external_template_mode = :fallback
    ReActionView.config.validation_mode = :raise

    assert_raises(Herb::Engine::CompilationError) do
      compile(INVALID, LOCAL)
    end

    assert_empty @log.string
  ensure
    ReActionView.config.validation_mode = nil
  end

  test "external templates never render a validation overlay in :fallback mode" do
    ReActionView.config.external_template_mode = :fallback
    ReActionView.config.validation_mode = :overlay

    compiled = compile(INVALID, EXTERNAL)

    refute_includes compiled, "data-herb-validation-error"
  ensure
    ReActionView.config.validation_mode = nil
  end
end

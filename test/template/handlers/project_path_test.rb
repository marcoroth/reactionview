# frozen_string_literal: true

require_relative "../../test_helper"

require "action_controller"

class ReActionView::ProjectPathTest < Minitest::Spec
  RAILS_ROOT = "/app"
  HOST_PATH = "/Users/you/myapp"
  VIEW = "/app/app/views/users/show.html.erb"
  LAYOUT = "/app/app/views/layouts/application.html.erb"

  before do
    @previous_debug_mode = ReActionView.config.debug_mode

    ReActionView.config.debug_mode = true
    ReActionView.config.project_path = nil
  end

  after do
    ReActionView.config.debug_mode = @previous_debug_mode
    ReActionView.config.project_path = nil
  end

  def compile(source, identifier: VIEW, virtual_path: "users/show")
    template = ActionView::Template.new(
      source,
      identifier,
      ReActionView::Template::Handlers::Herb,
      virtual_path: virtual_path,
      format: :html,
      locals: []
    )

    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      ReActionView::Template::Handlers::Herb.call(template, source)
    end
  end

  test "editor path is left alone when project_path is not configured" do
    compiled = compile("<div>Hello</div>")

    assert_includes compiled, %(data-herb-debug-file-full-path="/app/app/views/users/show.html.erb")
  end

  test "editor path is rewritten to the configured project_path" do
    ReActionView.config.project_path = HOST_PATH

    compiled = compile("<div>Hello</div>")

    assert_includes compiled, %(data-herb-debug-file-full-path="/Users/you/myapp/app/views/users/show.html.erb")
  end

  test "relative path stays correct when the editor path is rewritten" do
    ReActionView.config.project_path = HOST_PATH

    compiled = compile("<div>Hello</div>")

    assert_includes compiled, %(data-herb-debug-file-relative-path="app/views/users/show.html.erb")
  end

  test "herb-project-path meta tag keeps Rails.root so it matches the herb dev server" do
    ReActionView.config.project_path = HOST_PATH

    compiled = compile("<html><head></head><body></body></html>", identifier: LAYOUT, virtual_path: "layouts/application")

    # The head markup is compiled as a Ruby string literal now rather than written into the
    # template as text, so what appears in the source is the escaped form of it.
    assert_includes compiled, %(<meta name="herb-project-path" content="/app">).dump[1..-2]
    refute_includes compiled, %(<meta name="herb-project-path" content="#{HOST_PATH}">).dump[1..-2]
  end

  test "templates outside Rails.root stay undecorated even when project_path matches them" do
    ReActionView.config.project_path = HOST_PATH

    compiled = compile("<div>Hello</div>", identifier: "#{HOST_PATH}/app/views/users/show.html.erb")

    refute_includes compiled, "data-herb-debug"
  end

  test "compiled output without a configured project_path" do
    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      assert_compiled_snapshot(
        "<div><h1>Hello</h1></div>",
        handler: ReActionView::Template::Handlers::Herb,
        identifier: VIEW,
        virtual_path: "users/show",
        options: { project_path: nil }
      )
    end
  end

  test "compiled output with a configured project_path" do
    ReActionView.config.project_path = HOST_PATH

    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      assert_compiled_snapshot(
        "<div><h1>Hello</h1></div>",
        handler: ReActionView::Template::Handlers::Herb,
        identifier: VIEW,
        virtual_path: "users/show",
        options: { project_path: HOST_PATH }
      )
    end
  end

  test "evaluated output with a configured project_path" do
    ReActionView.config.project_path = HOST_PATH

    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      assert_evaluated_snapshot(
        "<div><h1>Hello</h1></div>",
        handler: ReActionView::Template::Handlers::Herb,
        identifier: VIEW,
        virtual_path: "users/show",
        options: { project_path: HOST_PATH }
      )
    end
  end
end

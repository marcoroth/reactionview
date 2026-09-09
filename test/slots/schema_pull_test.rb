# frozen_string_literal: true

require_relative "../test_helper"

require "action_controller"
require "rack/mock"
require "tmpdir"

class ReActionView::Slots::SchemaPullTest < Minitest::Spec
  SOURCE = <<~ERB
    <%# herb:slots client %>
    <p>Hello, <%= @name %></p>
  ERB

  class GreetingsController < ActionController::Base
    prepend ReActionView::Slots::Rendering

    def self.controller_path = "greetings"

    def show
      @name = "Marco"

      respond_to do |format|
        format.slots { render :show }
        format.html { render :show }
      end
    end
  end

  before do
    @previous = [ReActionView.config.slots, ReActionView.config.intercept_erb, ReActionView.config.debug_mode]

    ReActionView.config.slots = true
    ReActionView.config.intercept_erb = true
    ReActionView.config.debug_mode = false

    ActionView::Template.register_template_handler :erb, ReActionView::Template::Handlers::ERB
    Mime::Type.register(ReActionView::Slots::MIME_TYPE, ReActionView::Slots::FORMAT) unless Mime[ReActionView::Slots::FORMAT]
  end

  after do
    ReActionView.config.slots, ReActionView.config.intercept_erb, ReActionView.config.debug_mode = @previous

    ActionView::Template.register_template_handler :erb, ActionView::Template::Handlers::ERB
  end

  around do |work|
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "greetings"))
      File.write(File.join(root, "greetings", "show.html.erb"), SOURCE)

      GreetingsController.view_paths = [
        ReActionView::Slots::Resolver.new(root),
        ActionView::FileSystemResolver.new(root)
      ]

      work.call
    end
  end

  def dispatch(headers: {})
    env = Rack::MockRequest.env_for("/greetings", method: "GET")
    env["HTTP_ACCEPT"] = ReActionView::Slots::MIME_TYPE
    headers.each { |name, value| env["HTTP_#{name.upcase.tr("-", "_")}"] = value }

    status, _response_headers, body = GreetingsController.action(:show).call(env)
    payload = +""
    body.each { |chunk| payload << chunk }

    [status, JSON.parse(payload)]
  end

  it "answers values without schema by default" do
    status, payload = dispatch

    assert_equal 200, status
    assert payload.key?("slots")
    refute payload.key?("schema")
  end

  it "merges the schema envelope when the request asks for it" do
    _status, payload = dispatch(headers: { "Herb-Schema" => "1" })

    schema = payload.fetch("schema")

    assert_equal "client", schema["mode"]
    assert_equal payload["version"], schema["version"]
    assert schema["manifest"].key?("states") || schema["manifest"].key?("names")
    assert_includes schema["static_markup"], "herb-slot:0"
  end

  it "answers the same values either way" do
    _status, plain = dispatch
    _status, with_schema = dispatch(headers: { "Herb-Schema" => "1" })

    assert_equal plain["slots"], with_schema["slots"]
    assert_equal plain["version"], with_schema["version"]
  end
end

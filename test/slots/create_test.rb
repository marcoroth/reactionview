# frozen_string_literal: true

require_relative "../test_helper"

require "action_controller"
require "rack/mock"
require "tmpdir"

class ReActionView::Slots::CreateTest < Minitest::Spec
  SOURCE = <<~ERB
    <%# herb:slots client %>
    <ul><% @messages.each do |message| %><%# herb:key message[:id] %><li id="message_<%= message[:id] %>"><%= message[:body] %></li><% end %></ul>
  ERB

  class MessagesController < ActionController::Base
    prepend ReActionView::Slots::Rendering

    def self.controller_path = "messages"

    def show
      @messages = [{ id: 1, body: "first" }, { id: 2, body: "second" }]

      render :show
    end

    def create
      @messages = [{ id: 42, body: params[:body] }]

      respond_to do |format|
        format.slots { render :show, status: :created }
        format.html { redirect_to "/messages" }
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
      FileUtils.mkdir_p(File.join(root, "messages"))
      File.write(File.join(root, "messages", "show.html.erb"), SOURCE)

      MessagesController.view_paths = [
        ReActionView::Slots::Resolver.new(root),
        ActionView::FileSystemResolver.new(root)
      ]

      work.call
    end
  end

  def dispatch(action, method:, accept:, params: {})
    env = Rack::MockRequest.env_for("/messages", method: method, params: params)
    env["HTTP_ACCEPT"] = accept

    status, headers, body = MessagesController.action(action).call(env)

    joined = +""
    body.each { |chunk| joined << chunk }

    [status, headers, joined]
  end

  def post_create(body: "hello")
    dispatch(:create, method: "POST", accept: ReActionView::Slots::MIME_TYPE, params: { body: body })
  end

  test "a POST renders values, since the slots path never asks which verb" do
    status, _headers, body = post_create

    payload = JSON.parse(body)

    assert_equal 201, status
    assert_equal 0, payload["occurrence"]
    assert payload["version"]
  end

  test "rendering the page template gives the payload the page's identity" do
    _status, _headers, body = post_create

    payload = JSON.parse(body)

    assert_equal "messages/show", payload["template"].split("/").last(2).join("/").sub(".html.erb", "")
  end

  test "a one-element collection confirms exactly the row it carries" do
    _status, _headers, body = post_create(body: "just this one")

    payload = JSON.parse(body)
    collection = payload["slots"].values.find { |slot| slot.is_a?(Hash) && slot.key?("items") }

    assert_equal ["42"], collection["items"].keys
    assert_includes collection["items"]["42"].values, "just this one"
  end

  test "the version matches the page, since the digest covers schema and not data" do
    _status, _headers, created = post_create
    _status, _headers, shown = dispatch(:show, method: "GET", accept: ReActionView::Slots::MIME_TYPE)

    assert_equal JSON.parse(shown)["version"], JSON.parse(created)["version"]
  end

  test "an html POST still redirects the way a form expects" do
    status, headers, _body = dispatch(:create, method: "POST", accept: "text/html", params: { body: "hello" })

    assert_equal 302, status
    assert_equal "http://example.org/messages", headers["Location"]
  end
end

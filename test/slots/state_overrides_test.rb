# frozen_string_literal: true

require_relative "../test_helper"

require "action_controller"

class ReActionView::Slots::StateOverridesTest < Minitest::Spec
  Overrides = ReActionView::Slots::StateOverrides

  RAILS_ROOT = "/app"
  VIEW = "/app/app/views/users/show.html.erb"
  IDENTIFIER = "app/views/users/show.html.erb"

  STATE_SOURCE = <<~ERB
    <%# herb:state (open: true) %>
    <% if open %><span><%= @yes %></span><% else %><em><%= @no %></em><% end %>
  ERB

  before do
    @previous_slots = ReActionView.config.slots

    ReActionView.config.debug_mode = false
    ReActionView.config.slots = true

    Mime::Type.register(ReActionView::Slots::MIME_TYPE, ReActionView::Slots::FORMAT) unless Mime[ReActionView::Slots::FORMAT]
  end

  after do
    ReActionView.config.slots = @previous_slots
  end

  class View
    attr_accessor :__herb_state_overrides

    def initialize(**assigns)
      assigns.each { |name, value| instance_variable_set(:"@#{name}", value) }
    end
  end

  FakeRequest = Struct.new(:headers)

  class Helped
    include ReActionView::Slots::StateOverridesHelper

    attr_reader :request

    def initialize(request)
      @request = request
    end
  end

  class SteeredController
    include ReActionView::Slots::StateOverridesHelper
    prepend ReActionView::Slots::Rendering

    attr_reader :request, :response

    def initialize(headers)
      @request = ActionDispatch::Request.new(headers.transform_keys { |key| "HTTP_#{key.upcase.tr("-", "_")}" })
      @request.format = ReActionView::Slots::FORMAT
      @response = ActionDispatch::Response.new
    end

    def render_to_body(_options = {})
      "{}"
    end
  end

  def compile(source, format:)
    template = ActionView::Template.new(
      source,
      VIEW,
      ReActionView::Template::Handlers::Herb,
      virtual_path: "users/show",
      format: format,
      locals: []
    )

    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      ReActionView::Template::Handlers::Herb.call(template, source)
    end
  end

  def values(view)
    view.instance_eval(compile(STATE_SOURCE, format: :slots))
  end

  def steered(overrides, **assigns)
    view = View.new(**assigns)
    view.__herb_state_overrides = overrides

    values(view)
  end

  describe "parsing the header" do
    test "nothing for a blank header" do
      assert_nil Overrides.parse(nil)
      assert_nil Overrides.parse("")
      assert_nil Overrides.parse("   ")
    end

    test "nothing for a header past the size cap" do
      assert_nil Overrides.parse(%({"a":"#{"x" * 9000}"}))
    end

    test "nothing for junk" do
      assert_nil Overrides.parse("{not json")
      assert_nil Overrides.parse("[1,2]")
      assert_nil Overrides.parse(%("just a string"))
    end

    test "keeps only template entries shaped like state maps" do
      parsed = Overrides.parse(%({"a.html.erb":{"open":true},"b.html.erb":"junk"}))

      assert_equal({ "a.html.erb" => { "open" => true } }, parsed)
      assert_nil Overrides.parse(%({"a.html.erb":"junk"}))
    end
  end

  describe "the view helper" do
    test "reads and memoizes the header" do
      helped = Helped.new(FakeRequest.new({ Overrides::HEADER => %({"a.html.erb":{"open":false}}) }))

      assert_equal({ "a.html.erb" => { "open" => false } }, helped.__herb_state_overrides)
      assert_same helped.__herb_state_overrides, helped.__herb_state_overrides
    end

    test "answers nothing without a header" do
      assert_nil Helped.new(FakeRequest.new({})).__herb_state_overrides
    end

    test "answers nothing without a request" do
      helped = Helped.new(nil)

      assert_nil helped.__herb_state_overrides
    end
  end

  describe "reading state in a controller" do
    test "a state the client sent is one method call away" do
      controller = SteeredController.new(Overrides::HEADER => %({"app/views/chat/show.html.erb":{"q":"hello","open":false}}))

      assert_equal "hello", controller.herb_state("q")
      assert_equal false, controller.herb_state("open")
    end

    test "the default answers when the client said nothing" do
      controller = SteeredController.new(Overrides::HEADER => %({"app/views/chat/show.html.erb":{"q":"hello"}}))

      assert_equal "", controller.herb_state("missing", "")
      assert_equal "", SteeredController.new({}).herb_state("q", "")
    end

    test "no name hands over everything, keyed by template" do
      controller = SteeredController.new(Overrides::HEADER => %({"a.html.erb":{"q":"x"}}))

      assert_equal({ "a.html.erb" => { "q" => "x" } }, controller.herb_state)
      assert_nil SteeredController.new({}).herb_state
    end

    test "the first template naming the state wins" do
      controller = SteeredController.new(Overrides::HEADER => %({"a.html.erb":{"q":"first"},"b.html.erb":{"q":"second"}}))

      assert_equal "first", controller.herb_state("q")
    end
  end

  describe "steering the values program" do
    test "the defaults pick the compiled branch" do
      payload = values(View.new(yes: "shown", no: "hidden"))

      assert_equal "shown", payload[:slots][0][:slots].values.first
    end

    test "the client's state picks its branch" do
      payload = steered({ IDENTIFIER => { "open" => false } }, yes: "shown", no: "hidden")

      assert_equal "hidden", payload[:slots][0][:slots].values.first
    end

    test "a wrongly typed value falls back to the default" do
      payload = steered({ IDENTIFIER => { "open" => 7 } }, yes: "shown", no: "hidden")

      assert_equal "shown", payload[:slots][0][:slots].values.first
    end

    test "another template's state says nothing about this one" do
      payload = steered({ "app/views/other.html.erb" => { "open" => false } }, yes: "shown", no: "hidden")

      assert_equal "shown", payload[:slots][0][:slots].values.first
    end

    test "the page render ignores overrides entirely" do
      view = View.new(yes: "shown", no: "hidden")
      view.__herb_state_overrides = { IDENTIFIER => { "open" => false } }
      view.instance_variable_set(:@output_buffer, ActionView::OutputBuffer.new)

      rendered = view.instance_eval(compile(STATE_SOURCE, format: :html)).to_s

      assert_includes rendered, "shown"
      refute_includes rendered, "hidden"
    end
  end

  describe "cache hygiene" do
    test "a steered response is never stored" do
      controller = SteeredController.new(Overrides::HEADER => %({"a.html.erb":{"open":false}}))
      controller.render_to_body

      assert_equal "no-store", controller.response.headers["Cache-Control"]
    end

    test "an unsteered response keeps its caching" do
      controller = SteeredController.new({})
      controller.render_to_body

      assert_nil controller.response.headers["Cache-Control"]
    end
  end
end

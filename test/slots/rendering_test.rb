# frozen_string_literal: true

require_relative "../test_helper"

require "action_controller"
require "tmpdir"

class ReActionView::Slots::RenderingTest < Minitest::Spec
  SOURCE = %(<div class="<%= @tone %>"><h1><%= @title %></h1></div>)

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
      @root = root

      FileUtils.mkdir_p(File.join(root, "users"))
      File.write(File.join(root, "users", "show.html.erb"), SOURCE)

      work.call
    end
  end

  class Controller
    def render_to_body(options = {})
      options[:body]
    end
  end

  class Serializing < Controller
    prepend ReActionView::Slots::Rendering
  end

  Format = Struct.new(:symbol)
  Request = Struct.new(:format)

  class Normalizing
    attr_reader :request

    def initialize(format)
      @request = Request.new(Format.new(format))
    end

    def _normalize_options(options)
      options
    end
  end

  class NormalizingWithSlots < Normalizing
    prepend ReActionView::Slots::Rendering
  end

  class Rendering < Controller
    prepend ReActionView::Slots::Rendering

    attr_reader :lookup_context, :request

    def initialize(lookup_context, format)
      super()

      @lookup_context = lookup_context
      @request = Request.new(Format.new(format))
    end

    def _prefixes = []
  end

  def render(format, **assigns)
    lookup = ActionView::LookupContext.new(
      [ReActionView::Slots::Resolver.new(@root), ActionView::FileSystemResolver.new(@root)]
    )

    lookup.formats = [format]

    view = ActionView::Base.with_empty_template_cache.new(lookup, {}, nil)
    assigns.each { |name, value| view.instance_variable_set(:"@#{name}", value) }

    view.render(template: "users/show")
  end

  test "the format is one ActionView will accept" do
    assert_includes ActionView::Template::Types.symbols, ReActionView::Slots::FORMAT
  end

  test "a values request renders the payload rather than the page" do
    payload = render(:slots, tone: "calm", title: "Hello")

    assert_equal({ 0 => "calm", 1 => "Hello" }, payload[:slots])
    assert_equal "users/show", payload[:template].split("/").last(2).join("/").sub(".html.erb", "")
  end

  test "the payload names the version the page was marked with" do
    payload = render(:slots, tone: "calm", title: "Hello")

    assert_includes render(:html, tone: "calm", title: "Hello"), ":#{payload[:version]}:"
  end

  test "an html request still renders the page, markers and all" do
    rendered = render(:html, tone: "calm", title: "Hello")

    assert_includes rendered, "herb-region:"
    assert_includes rendered, %(<div class="calm" data-herb-slot="0:attribute:class">)
  end

  test "a value is escaped the way the page escaped it" do
    payload = render(:slots, tone: "calm", title: "Hi <b>")

    assert_equal "Hi &lt;b&gt;", payload[:slots][1]
    assert_includes render(:html, tone: "calm", title: "Hi <b>"), "Hi &lt;b&gt;"
  end

  describe "handing the payload to the response" do
    test "serializes the values, which nothing below here would do" do
      body = Serializing.new.render_to_body(body: { template: "a", slots: { 0 => "x" } })

      assert_equal %({"template":"a","slots":{"0":"x"}}), body
    end

    test "leaves a rendered page alone" do
      assert_equal "<p>hi</p>", Serializing.new.render_to_body(body: "<p>hi</p>")
    end
  end

  describe "the layout a values request does not get" do
    test "renders the action and nothing around it" do
      options = NormalizingWithSlots.new(ReActionView::Slots::FORMAT)._normalize_options({})

      assert_equal false, options[:layout]
    end

    test "leaves a page request to render its layout as usual" do
      options = NormalizingWithSlots.new(:html)._normalize_options({})

      refute_includes options.keys, :layout
    end
  end

  describe "the dependency map a page carries" do
    def page_body(format, body)
      lookup = ActionView::LookupContext.new([ReActionView::Slots::Resolver.new(@root), ActionView::FileSystemResolver.new(@root)])
      lookup.formats = [:html]

      previous = ReActionView.config.instance_variable_get(:@project_path)
      ReActionView.config.project_path = @root
      ReActionView::Slots.reset_dependencies!

      Rendering.new(lookup, format).render_to_body(body: body, template: "users/show")
    ensure
      ReActionView.config.project_path = previous
      ReActionView::Slots.reset_dependencies!
    end

    def slotted_page
      html = render(:html)

      "<html><body>#{html}</body></html>"
    end

    def delivered(body)
      session = ::Herb::Engine::Runtime::Session.capture { page_body(:html, body) }

      session.channel(::Herb::Engine::Slots::Dependencies::Channel::NAME) { nil }
    end

    test "carries what the page's state reaches" do
      map = delivered(slotted_page).to_html

      assert_includes map, "<template data-herb-dependencies>"
      assert_includes map, "@tone"
      assert_includes map, "@title"
    end

    test "hands it to the response rather than writing it into the page" do
      body = page_body(:html, slotted_page)

      refute_includes body, "data-herb-dependencies"
    end

    test "leaves a page with no slots alone, and hands over nothing" do
      assert_equal "<html><body><p>plain</p></body></html>", page_body(:html, "<html><body><p>plain</p></body></html>")
      assert_nil delivered("<html><body><p>plain</p></body></html>")
    end

    test "leaves a values response alone" do
      assert_equal "{\"a\":1}", page_body(ReActionView::Slots::FORMAT, { a: 1 })
    end
  end
end

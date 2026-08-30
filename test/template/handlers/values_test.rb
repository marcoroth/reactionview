# frozen_string_literal: true

require_relative "../../test_helper"

require "action_controller"

class ReActionView::ValuesTest < Minitest::Spec
  RAILS_ROOT = "/app"
  VIEW = "/app/app/views/users/show.html.erb"

  class View
    def initialize(**assigns)
      assigns.each { |name, value| instance_variable_set(:"@#{name}", value) }
    end
  end

  before do
    @previous_slots = ReActionView.config.slots

    ReActionView.config.debug_mode = false
    ReActionView.config.slots = true
  end

  after do
    ReActionView.config.slots = @previous_slots
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

  def values(source, view = View.new)
    view.instance_eval(compile(source, format: :slots))
  end

  def html(source, view = View.new)
    view.instance_variable_set(:@output_buffer, ActionView::OutputBuffer.new)

    view.instance_eval(compile(source, format: :html)).to_s
  end

  test "the two compiles name the same version, which is what says they belong together" do
    source = %(<div class="<%= @tone %>"><h1><%= @title %></h1></div>)

    assert_includes html(source), ":#{values(source)[:version]}:"
  end

  test "a value arrives escaped the way the page would have written it" do
    source = "<p><%= @name %></p>"
    view = View.new(name: "Ada <b>L</b>")

    assert_equal "Ada &lt;b&gt;L&lt;/b&gt;", values(source, view)[:slots][0]
    assert_includes html(source, View.new(name: "Ada <b>L</b>")), "Ada &lt;b&gt;L&lt;/b&gt;"
  end

  test "an attribute is escaped as the page escapes it, not as an attribute" do
    source = %(<div title="<%= @text %>"></div>)
    view = View.new(text: %(a > b))

    assert_equal "a &gt; b", values(source, view)[:slots][0]
    assert_includes html(source, View.new(text: %(a > b))), "a &gt; b"
  end

  test "a value already marked html_safe is left alone, as the page leaves it" do
    source = "<p><%= @markup %></p>"

    assert_equal "<b>bold</b>", values(source, View.new(markup: "<b>bold</b>".html_safe))[:slots][0]
  end

  test "every value it reports appears in the page rendered from the same state" do
    source = %(<div class="<%= @tone %>"><h1><%= @title %></h1><% @items.each do |i| %><li id="<%= i %>"><%= i %></li><% end %></div>)
    state = { tone: "calm", title: "Hello", items: %w[a b] }

    rendered = html(source, View.new(**state))
    reported = values(source, View.new(**state))[:slots]

    assert_equal "calm", reported[0]
    assert_equal({ "a" => { 3 => "a", 4 => "a" }, "b" => { 3 => "b", 4 => "b" } }, reported[2][:items])

    flatten(reported).each { |value| assert_includes rendered, value }
  end

  test "it counts a rendering the way the region marker counts it" do
    source = "<p><%= @name %></p>"
    view = View.new(name: "x")

    assert_equal [0, 1, 2], Array.new(3) { view.instance_eval(compile(source, format: :slots))[:occurrence] }
  end

  test "a template nothing asked to mark reports no values, since nothing can address it" do
    ReActionView.config.slots = false

    assert_empty values("<p><%= @name %></p>")
  end

  test "the html compile still gets its markers" do
    assert_includes html("<p><%= @name %></p>"), "herb-region:app/views/users/show.html.erb"
  end

  def flatten(slots, found = [])
    slots.each_value do |value|
      case value
      when String then found << value
      when Hash
        flatten(value[:slots], found) if value[:slots]
        value[:items]&.each_value { |item| flatten(item, found) }
      end
    end

    found
  end
end

# frozen_string_literal: true

require_relative "../../test_helper"

require "action_controller"

class ReActionView::SchemaTest < Minitest::Spec
  RAILS_ROOT = "/app"
  VIEW = "/app/app/views/users/show.html.erb"

  before do
    @previous_slots = ReActionView.config.slots

    ReActionView.config.debug_mode = false
    ReActionView.config.slots = :client
  end

  after do
    ReActionView.config.slots = @previous_slots
  end

  def schema(source)
    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      ReActionView::Template::Handlers::Herb.compile_for_schema(source, VIEW)
    end
  end

  def page_visitor(source)
    template = ActionView::Template.new(
      source,
      VIEW,
      ReActionView::Template::Handlers::Herb,
      virtual_path: "users/show",
      format: :html,
      locals: []
    )

    visitor = nil

    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      handler = ReActionView::Template::Handlers::Herb.new
      visitor = handler.send(:slot_visitors, template, source).first
      ReActionView.config.slot_mode_for(source)
      base = handler.send(:base_visitors, template)

      ReActionView::Template::Handlers::Herb.erb_implementation.new(
        source,
        filename: VIEW,
        project_path: RAILS_ROOT,
        visitors: [*base, visitor]
      ).src
    end

    visitor
  end

  it "agrees with the page compile about the version" do
    source = "<p><%= @name %></p><% if @open %><b>hi</b><% end %>"

    assert_equal page_visitor(source).version, schema(source).version
  end

  it "answers the mode the template compiles in" do
    assert_equal :client, schema("<p><%= @name %></p>").mode
    assert_equal :server, schema("<%# herb:slots server %>\n<p><%= @name %></p>").mode
  end

  it "parks statics only in client mode" do
    source = "<% if @open %><b>yes</b><% else %><i>no</i><% end %>"

    refute_nil schema(source).statics

    ReActionView.config.slots = :server

    server_statics = schema(source).statics

    assert server_statics.nil? || server_statics.empty?
  end

  it "carries the static markup" do
    result = schema("<p>Hello, <%= @name %></p>")

    assert_equal "<p>Hello, <!--herb-slot:0--><!--/herb-slot:0--></p>", result.static_markup
  end

  it "collects slot diagnostics" do
    source = "<%# herb:state (count: 0) %>\n<% count = 5 %>\n<p><%= count %></p>\n"
    result = schema(source)

    assert_equal(["herb-state-assignment"], result.diagnostics.map { |diagnostic| diagnostic.code.to_s })
  end

  it "still compiles for diagnostics when slots are off" do
    ReActionView.config.slots = false

    result = schema("<p><%= @name %></p>")

    assert_nil result.mode
    assert_nil result.version
  end
end

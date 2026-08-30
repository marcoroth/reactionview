# frozen_string_literal: true

require_relative "../../test_helper"

require "action_controller"

class ReActionView::SlotsTest < Minitest::Spec
  RAILS_ROOT = "/app"
  VIEW = "/app/app/views/users/show.html.erb"

  before do
    @previous_slots = ReActionView.config.slots

    ReActionView.config.debug_mode = false
    ReActionView.config.slots = false
  end

  after do
    ReActionView.config.slots = @previous_slots
  end

  def compile(source, identifier: VIEW, format: :html)
    template = ActionView::Template.new(
      source,
      identifier,
      ReActionView::Template::Handlers::Herb,
      virtual_path: "users/show",
      format: format,
      locals: []
    )

    Rails.stub(:root, Pathname.new(RAILS_ROOT)) do
      ReActionView::Template::Handlers::Herb.call(template, source)
    end
  end

  test "a template gets no markers when nothing asks for them" do
    compiled = compile("<p><%= @name %></p>")

    refute_includes compiled, "herb-slot"
    refute_includes compiled, "herb-region"
  end

  test "a template that asks for slots itself gets them" do
    compiled = compile("<%# herb:slots %>\n<p><%= @name %></p>")

    assert_includes compiled, "herb-region:app/views/users/show.html.erb"
    assert_includes compiled, %(data-herb-slot="0:child")
  end

  test "turning slots on marks every template" do
    ReActionView.config.slots = true

    assert_includes compile("<p><%= @name %></p>"), "herb-region:"
  end

  test "the project default decides who renders a branch" do
    ReActionView.config.slots = :client

    compiled = compile("<div><% if @admin %><b>secret</b><% else %><i>guest</i><% end %></div>")

    assert_includes compiled, "herb-branch:0:0"
    assert_includes compiled, "_herb_covered"
  end

  test "a template overrides the project default" do
    ReActionView.config.slots = :client

    compiled = compile("<%# herb:slots server %>\n<div><% if @admin %><b>secret</b><% end %></div>")

    assert_includes compiled, "herb-slot:0:conditional"
    refute_includes compiled, "_herb_covered"
  end

  test "a template can ask for client mode while the project stays on server" do
    ReActionView.config.slots = true

    compiled = compile("<%# herb:slots client %>\n<div><% if @admin %><b>secret</b><% end %></div>")

    assert_includes compiled, "_herb_covered"
  end

  test "only html gets markers" do
    ReActionView.config.slots = true

    refute_includes compile("Hello <%= @name %>", format: :text), "herb-region"
  end

  test "an unknown mode is refused" do
    error = assert_raises(ArgumentError) { ReActionView.config.slots = :nonsense }

    assert_match(/slots must be/, error.message)
  end
end

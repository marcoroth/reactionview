# frozen_string_literal: true

require_relative "../test_helper"

require "tmpdir"

class ReActionView::Slots::ResolverTest < Minitest::Spec
  def details(formats)
    { locale: [:en], formats: formats, variants: [], handlers: [:herb, :erb] }
  end

  def find(resolver, name, prefix, formats:, partial: false)
    resolver.find_all(name, prefix, partial, details(formats), nil, [])
  end

  around do |work|
    Dir.mktmpdir do |root|
      @root = root

      FileUtils.mkdir_p(File.join(root, "users"))
      FileUtils.mkdir_p(File.join(root, "layouts"))

      File.write(File.join(root, "users", "show.html.erb"), "<p><%= @name %></p>")
      File.write(File.join(root, "users", "_card.html.erb"), "<b><%= @name %></b>")
      File.write(File.join(root, "users", "export.text.erb"), "<%= @name %>")
      File.write(File.join(root, "layouts", "application.html.erb"), "<%= yield %>")

      @resolver = ReActionView::Slots::Resolver.new(root)

      work.call
    end
  end

  test "resolves the html template a values request asked for" do
    found = find(@resolver, "show", "users", formats: [:slots])

    assert_equal 1, found.size
    assert_equal :slots, found.first.format
    assert_equal "users/show", found.first.virtual_path
  end

  test "hands back the markup template's own source, so there is one template and not two" do
    found = find(@resolver, "show", "users", formats: [:slots])

    assert_equal "<p><%= @name %></p>", found.first.source
    assert_match(/show\.html\.erb\z/, found.first.identifier)
  end

  test "resolves a partial too, since a page is mostly partials" do
    found = find(@resolver, "card", "users", formats: [:slots], partial: true)

    assert_equal :slots, found.first.format
  end

  test "leaves an html request to the resolver Rails already built" do
    assert_empty find(@resolver, "show", "users", formats: [:html])
  end

  test "leaves a request that lists slots after html to the resolver Rails already built" do
    assert_empty find(@resolver, "show", "users", formats: [:html, :text, :slots])
  end

  test "still answers a request that lists slots ahead of html" do
    assert_equal :slots, find(@resolver, "show", "users", formats: [:slots, :html]).first.format
  end

  test "reads the requested order from the details key Rails passes when caching" do
    slots_first = ActionView::TemplateDetails::Requested.new(**details([:slots, :html]))
    html_first = ActionView::TemplateDetails::Requested.new(**details([:html, :slots]))

    assert_equal :slots, @resolver.find_all("show", "users", false, details([:slots, :html]), slots_first, []).first.format
    assert_empty @resolver.find_all("show", "users", false, details([:html, :slots]), html_first, [])
  end

  test "lets a lookup with default formats reach the markup template behind it" do
    Mime::Type.register(ReActionView::Slots::MIME_TYPE, ReActionView::Slots::FORMAT) unless Mime[ReActionView::Slots::FORMAT]

    view_paths = [@resolver, ActionView::FileSystemResolver.new(@root)]
    lookup = ActionView::LookupContext.new(view_paths, formats: ActionView::Template::Types.symbols)

    assert_includes lookup.formats, ReActionView::Slots::FORMAT
    assert_equal :html, lookup.find("show", ["users"]).format
  end

  test "lets a lookup that asks for slots reach the values template" do
    Mime::Type.register(ReActionView::Slots::MIME_TYPE, ReActionView::Slots::FORMAT) unless Mime[ReActionView::Slots::FORMAT]

    view_paths = [@resolver, ActionView::FileSystemResolver.new(@root)]
    lookup = ActionView::LookupContext.new(view_paths, formats: [ReActionView::Slots::FORMAT])

    assert_equal :slots, lookup.find("show", ["users"]).format
  end

  test "special cases no path, since nothing asks it for a layout" do
    assert_equal :slots, find(@resolver, "application", "layouts", formats: [:slots]).first.format
  end

  test "resolves nothing for a format that was never markup" do
    assert_empty find(@resolver, "export", "users", formats: [:slots])
  end
end

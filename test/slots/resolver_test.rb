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

  # A layout is rendered around the action, so its values would be the outermost payload rather
  # than the one that was asked for, and it would quietly replace the action's.
  test "resolves no layout" do
    assert_empty find(@resolver, "application", "layouts", formats: [:slots])
  end

  test "resolves nothing for a format that was never markup" do
    assert_empty find(@resolver, "export", "users", formats: [:slots])
  end
end

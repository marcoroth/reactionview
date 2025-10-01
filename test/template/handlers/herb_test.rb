# frozen_string_literal: true

require_relative "../../test_helper"

class HerbTemplateHandlerTest < Minitest::Test
  def setup
    ReActionView.config.debug_mode = false
    ReActionView.config.intercept_erb = true

    lookup_context = ActionView::LookupContext.new([])
    @view_context = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
    @handler = ReActionView::Template::Handlers::Herb.new
  end

  def test_error_for_invalid_html
    template_source = "Plain text: <%= 1 + 1 %> (<with_an_invalid_bracket>)"

    template = ActionView::Template.new(
      template_source,
      "test_template",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "test",
      format: :html,
      locals: []
    )

    result = template.render(@view_context, {})

    assert_includes result, "data-herb-parser-error"
  end

  def test_rendering_for_non_html_formats
    template_source = "Plain text: <%= 1 + 1 %> (<with_an_invalid_bracket>)"

    template = ActionView::Template.new(
      template_source,
      "test_template",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "test",
      format: :text,
      locals: []
    )

    result = template.render(@view_context, {})

    assert_equal "Plain text: 2 (<with_an_invalid_bracket>)", result
  end

  def test_compilation_basic_template
    template = "<h1>Hello <%= @name %></h1>"

    herb_engine = ReActionView::Template::Handlers::Herb::Herb.new(template)
    compiled_source = herb_engine.src

    assert_includes compiled_source, "@output_buffer"
    assert_includes compiled_source, ".append="
    assert_includes compiled_source, "Hello "

    refute_includes compiled_source, " src "
    refute_includes compiled_source, "flush_newline_if_pending(src)"
  end

  def test_compilation_with_blocks
    template = '<%= link_to "/users", class: "btn" do %>Click me<% end %>'

    herb_engine = ReActionView::Template::Handlers::Herb::Herb.new(template)
    compiled_source = herb_engine.src

    assert_includes compiled_source, 'link_to "/users", class: "btn" do'
    refute_includes compiled_source, '(link_to "/users", class: "btn" do'

    assert_includes compiled_source, "@output_buffer"
    assert_includes compiled_source, ".safe_append="
  end

  def test_compilation_escape_behavior
    template = "<%= @html %><%= raw @safe_html %>"

    herb_engine = ReActionView::Template::Handlers::Herb::Herb.new(template)
    compiled_source = herb_engine.src

    assert_includes compiled_source, ".append="
  end

  def test_compilation_newline_handling
    template = "<div>\n<%= @content %>\n</div>"

    herb_engine = ReActionView::Template::Handlers::Herb::Herb.new(template)
    compiled_source = herb_engine.src

    assert_includes compiled_source, ".safe_append="
    assert_includes compiled_source, "<div>"
    assert_includes compiled_source, "</div>"
  end

  def test_rendering_with_actionview
    template_source = "<h1>Hello <%= @name %>!</h1><p><%= @message %></p>"

    template = ActionView::Template.new(
      template_source,
      "test_template",
      ReActionView::Template::Handlers::Herb,
      virtual_path: "test",
      format: :html,
      locals: []
    )

    @view_context.instance_variable_set(:@name, "World")
    @view_context.instance_variable_set(:@message, "Welcome to ReActionView!")

    result = template.render(@view_context, {})

    assert_equal "<h1>Hello World!</h1><p>Welcome to ReActionView!</p>", result
  end

  def test_rendering_with_html_escaping
    template_source = "<div><%= @unsafe_content %></div>"

    template = ActionView::Template.new(
      template_source,
      "test_template",
      ReActionView::Template::Handlers::Herb,
      virtual_path: "test",
      format: :html,
      locals: []
    )

    @view_context.instance_variable_set(:@unsafe_content, '<script>alert("XSS")</script>')

    result = template.render(@view_context, {})

    assert_equal "<div>&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;</div>", result
  end

  def test_rendering_with_rails_helpers
    template_source = '<%= content_tag :div, "Hello", class: "greeting" %>'

    template = ActionView::Template.new(
      template_source,
      "test_template",
      ReActionView::Template::Handlers::Herb,
      virtual_path: "test",
      format: :html,
      locals: []
    )

    result = template.render(@view_context, {})

    assert_equal '<div class="greeting">Hello</div>', result
  end

  def test_rendering_with_link_to_block
    template_source = '<%= link_to "/users", class: "btn" do %>Click me<% end %>'

    template = ActionView::Template.new(
      template_source,
      "test_template",
      ReActionView::Template::Handlers::Herb,
      virtual_path: "test",
      format: :html,
      locals: []
    )

    result = template.render(@view_context, {})

    assert_includes result, "<a"
    assert_includes result, 'href="/users"'
    assert_includes result, 'class="btn"'
    assert_includes result, ">Click me</a>"
  end

  def test_rendering_complex_template
    template_source = <<~ERB
      <div class="user-card">
        <h2><%= @user[:name] %></h2>
        <%= if @user[:verified] %>
          <span class="badge">Verified</span>
        <% end %>
        <%= link_to user_path(@user[:id]), class: "btn btn-primary" do %>
          View Profile
        <% end %>
      </div>
    ERB

    template = ActionView::Template.new(
      template_source,
      "test_template",
      ReActionView::Template::Handlers::Herb,
      virtual_path: "test",
      format: :html,
      locals: []
    )

    def @view_context.user_path(id)
      "/users/#{id}"
    end

    @view_context.instance_variable_set(:@user, {
      name: "John Doe",
      verified: true,
      id: 123,
    })

    result = template.render(@view_context, {})

    assert_includes result, '<div class="user-card">'
    assert_includes result, "<h2>John Doe</h2>"
    assert_includes result, '<span class="badge">Verified</span>'
    assert_includes result, 'href="/users/123"'
    assert_includes result, "View Profile"
  end

  def test_rendering_complex_erb_constructs
    template_source = <<~ERB
      <div class="container py-8">
        <h1 class="title"><%= title "Events by Country" %></h1>

        <%= ui_button "View all cities", url: cities_path, kind: :secondary %>

        <% if @show_countries %>
          <h2>Countries</h2>
          <%= link_to country_path("switzerland"), id: "country-ch", class: "event-item" do %>
            <span class="event-name">🇨🇭 Switzerland</span>
            <%= ui_badge(5, kind: :secondary, class: "event-count") %>
          <% end %>
        <% end %>
      </div>
    ERB

    template = ActionView::Template.new(
      template_source,
      "test_template",
      ReActionView::Template::Handlers::Herb,
      virtual_path: "test",
      format: :html,
      locals: []
    )

    def @view_context.title(text)
      text
    end

    def @view_context.ui_button(text, **_options)
      "<button class=\"btn\">#{text}</button>".html_safe
    end

    def @view_context.cities_path
      "/cities"
    end

    def @view_context.country_path(slug)
      "/countries/#{slug}"
    end

    def @view_context.ui_badge(count, **_options)
      "<span class=\"badge\">#{count}</span>".html_safe
    end

    @view_context.instance_variable_set(:@show_countries, true)

    result = template.render(@view_context, {})

    assert_includes result, '<div class="container py-8">'
    assert_includes result, '<h1 class="title">Events by Country</h1>'
    assert_includes result, '<button class="btn">View all cities</button>'

    assert_includes result, "<h2>Countries</h2>"

    assert_includes result, "<a"
    assert_includes result, 'href="/countries/switzerland"'
    assert_includes result, 'id="country-ch"'
    assert_includes result, 'class="event-item"'
    assert_includes result, ">🇨🇭 Switzerland</span>"
    assert_includes result, '<span class="badge">5</span>'
    assert_includes result, "</a>"
  end
end

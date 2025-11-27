# frozen_string_literal: true

require_relative "../../test_helper"

class Herb::TemplateHandlerTest < Minitest::Spec
  before do
    ReActionView.config.debug_mode = false
    ReActionView.config.intercept_erb = true

    lookup_context = ActionView::LookupContext.new([])
    @view_context = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
  end

  test "rendering for non-html formats" do
    template = "Plain text: <%= 1 + 1 %> (<with_an_invalid_bracket>)"

    assert_compiled_snapshot(template, format: :text)
    assert_evaluated_snapshot(template, format: :text, ivars: { name: "User" })
  end

  test "error for invalid html" do
    template = "Plain text: <%= 1 + 1 %> (<with_an_invalid_bracket>)"

    assert_compiled_snapshot(template, format: :html)
    assert_evaluated_snapshot(template, format: :html, ivars: { name: "User" })
  end

  test "template with expression" do
    template = %(<h1>Hello <%= @name %></h1>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { name: "User" })
  end

  test "link_to with block" do
    template = %(<%= link_to "/users", class: "btn" do %>Click me<% end %>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template)
  end

  test "raw and regular output" do
    template = %(<%= @html %><%= raw @safe_html %>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: {
      html: "<b>bold</b>",
      safe_html: "<i>italic</i>",
    })
  end

  test "template with newlines" do
    template = %(<div>\n<%= @content %>\n</div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { content: "Hello" })
  end

  test "multiple expressions" do
    template = %(<h1>Hello <%= @name %>!</h1><p><%= @message %></p>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: {
      name: "World",
      message: "Welcome to ReActionView!",
    })
  end

  test "xss protection" do
    template = %(<div><%= @unsafe_content %></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: {
      unsafe_content: '<script>alert("XSS")</script>',
    })
  end

  test "content_tag helper" do
    template = %(<%= content_tag :div, "Hello", class: "greeting" %>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template)
  end

  test "user card with conditional and link_to" do
    template = <<~HTML
      <div class="user-card">
        <h2><%= @user[:name] %></h2>
        <%= if @user[:verified] %>
          <span class="badge">Verified</span>
        <% end %>
        <%= link_to user_path(@user[:id]), class: "btn btn-primary" do %>
          View Profile
        <% end %>
      </div>
    HTML

    def @view_context.user_path(id)
      "/users/#{id}"
    end

    template_obj = ActionView::Template.new(
      template,
      "test_template",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "test",
      format: :html,
      locals: []
    )
    compiled_source = template_obj.handler.call(template_obj, template)

    @view_context.instance_variable_set(:@user, {
      name: "John Doe",
      verified: true,
      id: 123,
    })

    result = @view_context.instance_eval(compiled_source).to_s

    assert_compiled_snapshot(template)

    normalized_result = result.gsub(/>\s+</, "><").gsub(/\s+/, " ").strip
    assert_equal '<div class="user-card"><h2>John Doe</h2><span class="badge">Verified</span><a class="btn btn-primary" href="/users/123"> View Profile </a></div>', normalized_result
  end

  test "complex layout with helpers" do
    template = <<~HTML
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
    HTML

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

    template_obj = ActionView::Template.new(
      template,
      "test_template",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "test",
      format: :html,
      locals: []
    )
    compiled_source = template_obj.handler.call(template_obj, template)

    @view_context.instance_variable_set(:@show_countries, true)
    result = @view_context.instance_eval(compiled_source).to_s

    assert_compiled_snapshot(template)

    assert_includes result, '<div class="container py-8">'
    assert_includes result, '<h1 class="title">Events by Country</h1>'
    assert_includes result, '<button class="btn">View all cities</button>'
    assert_includes result, "<h2>Countries</h2>"
    assert_includes result, 'href="/countries/switzerland"'
    assert_includes result, 'id="country-ch"'
    assert_includes result, 'class="event-item"'
    assert_includes result, ">🇨🇭 Switzerland</span>"
    assert_includes result, '<span class="badge">5</span>'
  end

  test "combobox data attribute with string array" do
    template = %(<div data-controller="combobox" data-combobox-choices-value="<%= @choices.to_json %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { choices: ["Volkslied", "Weihnachtslied", "foo"] })
  end

  test "data attribute with json_escape helper" do
    template = %(<div data-holidays-current-value="<%= json_escape(@holidays.to_json) %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { holidays: ["2025-10-20", "2025-10-21", "2025-11-26"] })
  end

  test "data attribute with nested object" do
    template = %(<div data-config="<%= @config.to_json %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { config: { key: "value" } })
    assert_evaluated_snapshot(template, ivars: {
      config: {
        name: "Test",
        options: { enabled: true, count: 42 },
        items: ["a", "b"],
      },
    })
  end

  test "special html characters in json" do
    template = %(<div data-value="<%= @value.to_json %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { value: ["<script>", "a & b", "x > y"] })
  end

  test "script with raw helper and json" do
    template = %(<script>window.config = <%= raw @config.to_json %></script>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { config: { key: "value", number: 123 } })
  end

  test "script with application json type" do
    template = %(<script type="application/json"><%= @data.to_json.html_safe %></script>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { data: { items: ["one", "two"], count: 2 } })
  end

  test "style with multiple custom properties" do
    template = %(<style>:root { --primary: <%= @primary %>; --secondary: <%= @secondary %>; }</style>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: {
      primary: "#FF0000",
      secondary: "rgb(0, 255, 0)",
    })
  end

  test "empty json structures" do
    template = %(<div data-empty-array="<%= @empty_array.to_json %>" data-empty-object="<%= @empty_object.to_json %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: {
      empty_array: [],
      empty_object: {},
    })
  end

  test "json with primitive types" do
    template = %(<div data-values="<%= @values.to_json %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: {
      values: {
        active: true,
        disabled: false,
        count: 42,
        price: 19.99,
        nothing: nil,
      },
    })
  end

  test "script with javascript expression" do
    template = %(<script>const data = <%= @data.to_json.html_safe %>; console.log(data);</script>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { data: { message: "Hello, World!" } })
  end

  test "data attributes with json" do
    template = %(<div data-value="<%= @data.to_json %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { data: ["foo", "bar"] })
  end

  test "script tag with json" do
    template = %(<script>window.data = <%= @data.to_json.html_safe %></script>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { data: { key: "value", items: [1, 2, 3] } })
  end

  test "multiline script with hash" do
    template = <<~HTML
      <script>
        window.railsVariables = <%= @hash.to_json.html_safe %>
      </script>
    HTML

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { hash: { a: "first_item", b: "second_item" } })
  end

  test "canvas with boolean array and multiple attributes" do
    template = <<~HTML
      <canvas
        data-controller="chart"
        data-chart-unit-type-value="<%= @unit_type %>"
        data-chart-data-value="<%= @data.to_json %>"
        data-chart-labels-value="<%= @labels.to_json %>"
        data-chart-unit-value="<%= @unit_label %>"
      ></canvas>
    HTML

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: {
      unit_type: "yes/no",
      data: [true, true, true, true, true, true],
      labels: ["2025-05-16", "2025-05-17", "2025-05-19", "2025-05-20", "2025-07-28", "2025-09-12"],
      unit_label: "sessions",
    })
  end

  test "concat" do
    template = %(<div data-json="<% concat(@data.to_json) %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { data: { a: 1 } })
  end

  test "raw helper with json" do
    template = %(<div data-config="<%= raw @config.to_json %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { config: { key: "value" } })
  end

  test "raw output" do
    template = %(<div data-config="<%== @config.to_json %>"></div>)

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template, ivars: { config: { key: "value" } })
  end
end

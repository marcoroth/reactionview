# frozen_string_literal: true

require_relative "../../test_helper"

class Herb::TemplateHandlerTest < Minitest::Spec
  before do
    ReActionView.config.debug_mode = false
    ReActionView.config.intercept_erb = true

    lookup_context = ActionView::LookupContext.new([])
    @view_context = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
    @view_context.instance_variable_set(:@output_buffer, ActionView::OutputBuffer.new)
  end

  test "rendering for non-html formats" do
    template = "Plain text: <%= 1 + 1 %> (<with_an_invalid_bracket>)"

    assert_evaluated_snapshot(template, format: :text, ivars: { name: "User" })
  end

  test "error for invalid html" do
    template = "Plain text: <%= 1 + 1 %> (<with_an_invalid_bracket>)"

    error = assert_raises(::Herb::Engine::ParseError) do
      assert_compiled_snapshot(template, format: :html)
    end

    assert_match(/MissingClosingTag/, error.detailed_message)
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

    template_object = ActionView::Template.new(
      template,
      "test_template",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "test",
      format: :html,
      locals: []
    )
    compiled_source = template_object.handler.call(template_object, template)

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

    template_object = ActionView::Template.new(
      template,
      "test_template",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "test",
      format: :html,
      locals: []
    )
    compiled_source = template_object.handler.call(template_object, template)

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

  test "render with block (e.g. component with do/end)" do
    template = <<~HTML
      <% if true %>
        <%= content_tag(:div, class: "wrapper") do %>
          <p>Hello</p>
        <% end %>
      <% else %>
        <%= content_tag(:div, class: "fallback") do %>
          <p>Fallback</p>
        <% end %>
      <% end %>
    HTML

    assert_compiled_snapshot(template)
    assert_evaluated_snapshot(template)
  end

  test "inline comment on expression compiles to valid Ruby" do
    template = %(<%= render(component) # rubocop:disable Some/Rule %>)

    assert_compiled_snapshot(template)
  end

  test "heredoc with trailing arguments compiles to valid Ruby" do
    template = <<~ERB
      <%= method_call <<~GRAPHQL, variables
        query {
          field
        }
      GRAPHQL
      %>
    ERB

    assert_compiled_snapshot(template)
  end

  test "renders templates that are not local with ActionView's ERB handler" do
    ReActionView.config.intercept_erb = true

    template = %(<p><h2>I am invalid</h2></p>)
    template_object = ActionView::Template.new(
      template,
      "test_template",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "test",
      format: :html,
      locals: []
    )

    compiled_source = Rails.stub(:root, Pathname.new("/local/template")) do
      template_object.handler.call(template_object, template)
    end

    result = @view_context.instance_eval(compiled_source).to_s

    normalized_result = result.gsub(/>\s+</, "><").gsub(/\s+/, " ").strip
    assert_equal "<p><h2>I am invalid</h2></p>", normalized_result
  end

  test "renders templates from gems vendored inside the application with ActionView's ERB handler" do
    ReActionView.config.intercept_erb = true

    template = %(<p><h2>I am invalid</h2></p>)
    template_object = ActionView::Template.new(
      template,
      "/app/vendor/bundle/ruby/3.4.0/gems/actionpack-8.1.2/lib/action_dispatch/middleware/templates/rescues/routing_error.html.erb",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "rescues/routing_error",
      format: :html,
      locals: []
    )

    compiled_source = Rails.stub(:root, Pathname.new("/app")) do
      Bundler.stub(:bundle_path, Pathname.new("/app/vendor/bundle")) do
        template_object.handler.call(template_object, template)
      end
    end

    result = @view_context.instance_eval(compiled_source).to_s

    normalized_result = result.gsub(/>\s+</, "><").gsub(/\s+/, " ").strip
    assert_equal "<p><h2>I am invalid</h2></p>", normalized_result
  end

  test "processes application templates when gems are vendored inside the application" do
    ReActionView.config.intercept_erb = true
    ReActionView.config.debug_mode = true

    template = %(<div><h1>Hello</h1></div>)
    template_object = ActionView::Template.new(
      template,
      "/app/app/views/users/show.html.erb",
      ReActionView::Template::Handlers::ERB,
      virtual_path: "users/show",
      format: :html,
      locals: []
    )

    compiled_source = Rails.stub(:root, Pathname.new("/app")) do
      Bundler.stub(:bundle_path, Pathname.new("/app/vendor/bundle")) do
        template_object.handler.call(template_object, template)
      end
    end

    assert_includes compiled_source, %(data-herb-debug-file-full-path="/app/app/views/users/show.html.erb")
  end

  test "instrumentation runs after the slots visitor and keeps its markers" do
    require "herb/engine/visitors/instrumentation_visitor"

    previous = ReActionView.config.engine.visitors.dup
    ReActionView.config.engine.visitors.use(::Herb::Engine::InstrumentationVisitor.new)

    template = %(<%# herb:slots client %>\n<p><%= @name %></p>)

    assert_compiled_snapshot(template, handler: ReActionView::Template::Handlers::Herb)
  ensure
    ReActionView.config.engine.visitors.replace(previous)
  end

  class StyleReadingVisitor < Herb::Visitor
    def self.reads_style_blocks? = true
  end

  test "a visitor is arranged by what it declares, wherever the app added it" do
    require "herb/engine/scoped_style/visitor"

    previous = ReActionView.config.engine.visitors.dup
    ReActionView.config.engine.visitors.use(StyleReadingVisitor.new)
    ReActionView.config.engine.visitors.use(::Herb::Engine::ScopedStyle::Visitor.new)

    template = %(<%# herb:slots client %>\n<style scoped>p { color: red }</style>\n<p><%= @name %></p>)

    assert_compiled_snapshot(template, handler: ReActionView::Template::Handlers::Herb)
  ensure
    ReActionView.config.engine.visitors.replace(previous)
  end

  def compile_with_engine_parser_options(options)
    previous = ReActionView.config.engine.parser_options
    ReActionView.config.engine.parser_options = options

    yield
  ensure
    ReActionView.config.engine.parser_options = previous
  end

  test "parser options on the engine reach the page compile" do
    source = %(<%# herb:slots client %>\n<p><%= @name %></p>)
    template_object = ActionView::Template.new(source, "/app/app/views/users/show.html.erb", ReActionView::Template::Handlers::Herb, virtual_path: "users/show", format: :html, locals: [])
    implementation = ReActionView::Template::Handlers::Herb.erb_implementation
    original = implementation.method(:new)
    captured = nil

    compile_with_engine_parser_options({ strict_locals: true }) do
      implementation.stub(:new, lambda { |compiled, config = {}|
        captured = config[:parser_options]
        original.call(compiled, config)
      }) do
        Rails.stub(:root, Pathname.new("/app")) { ReActionView::Template::Handlers::Herb.call(template_object, source) }
      end
    end

    assert_equal true, captured[:strict_locals]
  end

  test "parser options on the engine reach a block compile" do
    source = %(<%# herb:slots client %>\n<Async><p><%= @name %></p><Fallback><p>wait</p></Fallback></Async>)
    original = ::Herb::Engine::Slots::DynamicsCompiler.method(:new)
    captured = nil

    compile_with_engine_parser_options({ strict_locals: true }) do
      ::Herb::Engine::Slots::DynamicsCompiler.stub(:new, lambda { |compiled, config = {}|
        captured = config[:parser_options]
        original.call(compiled, config)
      }) do
        Rails.stub(:root, Pathname.new("/app")) { ReActionView::Template::Handlers::Herb.compile_for_block(source, "/app/app/views/users/show.html.erb", 0) }
      end
    end

    assert_equal true, captured[:strict_locals]
  end

  test "the project's parser options still apply when the engine has none" do
    source = %(<%# herb:slots client %>\n<p><%= @name %></p>)
    template_object = ActionView::Template.new(source, "/app/app/views/users/show.html.erb", ReActionView::Template::Handlers::Herb, virtual_path: "users/show", format: :html, locals: [])
    implementation = ReActionView::Template::Handlers::Herb.erb_implementation
    original = implementation.method(:new)
    captured = :untouched

    implementation.stub(:new, lambda { |compiled, config = {}|
      captured = config.key?(:parser_options)
      original.call(compiled, config)
    }) do
      Rails.stub(:root, Pathname.new("/app")) { ReActionView::Template::Handlers::Herb.call(template_object, source) }
    end

    assert_equal false, captured
  end

  test "a parser option on the engine that a visitor requires otherwise raises at compile" do
    source = %(<%# herb:slots client %>\n<p><%= @name %></p>)
    template_object = ActionView::Template.new(source, "/app/app/views/users/show.html.erb", ReActionView::Template::Handlers::Herb, virtual_path: "users/show", format: :html, locals: [])

    error = compile_with_engine_parser_options({ track_locations: false }) do
      assert_raises(ArgumentError) do
        Rails.stub(:root, Pathname.new("/app")) { ReActionView::Template::Handlers::Herb.call(template_object, source) }
      end
    end

    assert_equal "Herb::Engine::Validators::SecurityValidator requires the `track_locations` parser option to be true, but it is set to false", error.message
  end

  test "reuses the Rails builtin Herb implementation when available" do
    skip "Rails ships no builtin Herb implementation" unless defined?(ActionView::Template::Handlers::ERB::Herb)

    assert_operator ReActionView::Template::Handlers::Herb::Herb, :<, ActionView::Template::Handlers::ERB::Herb
  end
end

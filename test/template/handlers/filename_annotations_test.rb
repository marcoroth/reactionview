# frozen_string_literal: true

require_relative "../../test_helper"

class ReActionView::FilenameAnnotationsTest < Minitest::Spec
  HANDLERS = {
    erb: ReActionView::Template::Handlers::ERB,
    herb: ReActionView::Template::Handlers::Herb,
  }.freeze

  before do
    @previous_annotations = ActionView::Base.annotate_rendered_view_with_filenames
    @previous_debug_mode = ReActionView.config.debug_mode
    @previous_intercept_erb = ReActionView.config.intercept_erb
    @previous_slots = ReActionView.config.slots
    @previous_external_mode = ReActionView.config.external_template_mode

    ActionView::Base.annotate_rendered_view_with_filenames = true
    ReActionView.config.debug_mode = false
    ReActionView.config.intercept_erb = true
    ReActionView.config.slots = false

    @view = ActionView::Base.with_empty_template_cache.new(ActionView::LookupContext.new([]), {}, nil)
    @view.instance_variable_set(:@output_buffer, ActionView::OutputBuffer.new)
  end

  after do
    ActionView::Base.annotate_rendered_view_with_filenames = @previous_annotations
    ReActionView.config.debug_mode = @previous_debug_mode
    ReActionView.config.intercept_erb = @previous_intercept_erb
    ReActionView.config.slots = @previous_slots
    ReActionView.config.external_template_mode = @previous_external_mode
  end

  def template(source, extension: :herb, format: :html, identifier: "/app/app/views/users/show.#{format}.#{extension}")
    ActionView::Template.new(
      source, identifier, HANDLERS.fetch(extension),
      virtual_path: "users/show", format: format, locals: []
    )
  end

  def compile(template)
    Rails.stub(:root, Pathname.new("/app")) { template.handler.call(template, template.source) }
  end

  def annotated(body, identifier)
    "<!-- BEGIN #{identifier}\n-->#{body}<!-- END #{identifier} -->"
  end

  HANDLERS.each_key do |extension|
    test "#{extension} HTML uses the Rails filename comments and preserves escaping and the buffer" do
      object = template("<p><%= '<unsafe>' %><%= '<b>safe</b>'.html_safe %></p>", extension: extension)
      buffer = @view.instance_variable_get(:@output_buffer)
      result = @view.instance_eval(compile(object))

      assert_same buffer, result
      assert_equal annotated("<p>&lt;unsafe&gt;<b>safe</b></p>", "app/views/users/show.html.#{extension}"), result.to_s
    end

    test "#{extension} HTML is not annotated when the setting is disabled" do
      ActionView::Base.annotate_rendered_view_with_filenames = false

      assert_equal "<p>Hello</p>", @view.instance_eval(compile(template("<p>Hello</p>", extension: extension))).to_s
    end

    test "#{extension} non-HTML is not annotated" do
      object = template("Hello <%= 1 + 1 %>", extension: extension, format: :text)

      assert_equal "Hello 2", @view.instance_eval(compile(object)).to_s
    end

    test "#{extension} filename annotations stream through the supplied buffer" do
      object = template("<p><%= '<unsafe>' %></p>", extension: extension)
      chunks = []
      buffer = ActionView::StreamingBuffer.new(->(chunk) { chunks << chunk })

      Rails.stub(:root, Pathname.new("/app")) { object.render(@view, {}, buffer) }

      assert_equal annotated("<p>&lt;unsafe&gt;</p>", "app/views/users/show.html.#{extension}"), chunks.join
      assert_equal "<!-- BEGIN app/views/users/show.html.#{extension}\n-->", chunks.first
      assert_equal "<!-- END app/views/users/show.html.#{extension} -->", chunks.last
    end

    test "#{extension} annotations do not shift exception source lines" do
      object = template("<div>\n<% raise 'failure' %>\n</div>", extension: extension)
      compiled = compile(object)
      error = assert_raises(RuntimeError) { @view.instance_eval(compiled, object.identifier, 1) }

      assert_equal 2, error.backtrace_locations.first.lineno
      assert_equal object.identifier, error.backtrace_locations.first.path
    end
  end

  test "annotation selection happens at compile time" do
    compiled = compile(template("<p>Hello</p>"))
    ActionView::Base.annotate_rendered_view_with_filenames = false

    assert_equal annotated("<p>Hello</p>", "app/views/users/show.html.herb"), @view.instance_eval(compiled).to_s
  end

  test "filename literals safely preserve quotes, backslashes, interpolation and newlines" do
    identifier = "/app/app/views/a'\"\\\#{raise 'injected'}\n.html.herb"
    object = template("<p>Hello</p>", identifier: identifier)
    compiled = compile(object)

    assert_empty Prism.parse(compiled).errors
    assert_equal annotated("<p>Hello</p>", identifier.delete_prefix("/app/")), @view.instance_eval(compiled).to_s
  end

  test "nested templates keep their own comments inside the parent comments" do
    child = template("<span>Child</span>", identifier: "/app/app/views/users/_child.html.herb")
    @view.instance_variable_set(:@child_source, compile(child))
    def @view.render_child
      capture { instance_eval(@child_source) }
    end
    parent = template("<div><%= render_child %></div>", extension: :erb)

    assert_equal annotated(
      "<div>#{annotated("<span>Child</span>", "app/views/users/_child.html.herb")}</div>",
      "app/views/users/show.html.erb"
    ), @view.instance_eval(compile(parent)).to_s
  end

  test "ERB fallback keeps Rails annotations without duplicates" do
    ReActionView.config.external_template_mode = :fallback
    object = template("<p><h2>Invalid</h2></p>", extension: :erb, identifier: "/gems/example/app/views/show.html.erb")

    assert_equal annotated("<p><h2>Invalid</h2></p>", object.identifier), @view.instance_eval(compile(object)).to_s
  end

  test "nonintercepted ERB keeps Rails annotations without duplicates" do
    ReActionView.config.intercept_erb = false
    object = template("<p>Hello</p>", extension: :erb)

    assert_equal annotated("<p>Hello</p>", "app/views/users/show.html.erb"), @view.instance_eval(compile(object)).to_s
  end

  test "reactive HTML keeps filename comments outside slot markers while values remain a hash" do
    ReActionView.config.slots = :client
    source = "<p><%= @name %></p>"
    @view.instance_variable_set(:@name, "<unsafe>")
    html = @view.instance_eval(compile(template(source))).to_s
    values = @view.instance_eval(compile(template(source, format: :slots)))

    assert html.start_with?("<!-- BEGIN app/views/users/show.html.herb\n--><!--herb-region:")
    assert html.end_with?("<!--/herb-region:app/views/users/show.html.herb--><!-- END app/views/users/show.html.herb -->")
    assert_kind_of Hash, values
    assert_equal "&lt;unsafe&gt;", values[:slots][0]
  end

  test "slot values and auxiliary compiles are unchanged by annotations" do
    source = "<%# herb:slots client %>\n<Async><p><%= @name %></p><Fallback><p>wait</p></Fallback></Async>"
    handler = ReActionView::Template::Handlers::Herb
    object = template(source, format: :slots)

    Rails.stub(:root, Pathname.new("/app")) do
      with_annotations = object.handler.call(object, source)
      block = handler.compile_for_block(source, object.identifier, 0)
      markup = handler.compile_for_schema(source, object.identifier).static_markup
      version = handler.compile_for_dependencies(source, object.identifier).version

      ActionView::Base.annotate_rendered_view_with_filenames = false

      assert_equal with_annotations, object.handler.call(object, source)
      assert_equal block, handler.compile_for_block(source, object.identifier, 0)
      assert_equal markup, handler.compile_for_schema(source, object.identifier).static_markup
      assert_equal version, handler.compile_for_dependencies(source, object.identifier).version
      refute_includes with_annotations, "<!-- BEGIN"
    end
  end
end

# frozen_string_literal: true

module ReActionView
  class TimingVisitor < Herb::Visitor
    def initialize(template_name:, template_path:, template_identifier:)
      super()

      @template_name = template_name
      @template_path = template_path
      @template_identifier = template_identifier
      @top_level_elements = []
      @id_attribute_added = false
      @timing_injected = false
    end

    def visit_document_node(node)
      find_top_level_elements(node)

      inject_timing_start(node) unless @timing_injected

      super

      inject_timing_end(node) unless @timing_injected

      @timing_injected = true
    end

    def visit_html_element_node(node)
      add_render_id_to_element(node.open_tag) if should_add_render_id?(node)

      super
    end

    private

    def inject_timing_start(document_node)
      id_generation_node = create_erb_code_node(
        "__reactionview_render_id = \"rv_\#{Time.now.to_i}_\#{rand(100000)}\""
      )

      timing_start_node = create_erb_code_node(
        "__reactionview_timing_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)"
      )

      document_node.children.unshift(timing_start_node)
      document_node.children.unshift(id_generation_node)
    end

    def inject_timing_end(document_node)
      timing_end_node = create_erb_code_node(
        "__reactionview_timing_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)"
      )

      timing_calculation_node = create_erb_code_node(
        "__reactionview_timing_ms = ((__reactionview_timing_end - __reactionview_timing_start) * 1000).round(2)"
      )

      escaped_name = @template_name.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
      escaped_path = @template_path.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
      escaped_id = @template_identifier.gsub("\\", "\\\\\\\\").gsub('"', '\\"')

      timing_storage_node = create_erb_code_node(<<~RUBY.strip)
        Thread.current[:reactionview_timings] ||= {};
        Thread.current[:reactionview_timings][__reactionview_render_id] = {
          duration: __reactionview_timing_ms,
          template: "#{escaped_name}",
          path: "#{escaped_path}",
          identifier: "#{escaped_id}"
        }
      RUBY

      document_node.children << timing_end_node
      document_node.children << timing_calculation_node
      document_node.children << timing_storage_node
    end

    def find_top_level_elements(document_node)
      @top_level_elements = []

      document_node.children.each do |child|
        @top_level_elements << child if child.is_a?(Herb::AST::HTMLElementNode)
      end
    end

    def should_add_render_id?(element_node)
      return false if @id_attribute_added
      return false unless @top_level_elements.first == element_node

      true
    end

    def add_render_id_to_element(open_tag_node)
      return if @id_attribute_added

      id_attribute = create_erb_attribute("data-reactionview-id", "__reactionview_render_id")
      open_tag_node.children << id_attribute

      @id_attribute_added = true
    end

    def create_static_attribute(name, value)
      name_node = create_html_attribute_name_node(name)
      value_literal = create_literal_node(value)
      value_node = create_html_attribute_value_node([value_literal])

      create_html_attribute_node(name_node, value_node)
    end

    def create_erb_attribute(name, ruby_variable)
      name_node = create_html_attribute_name_node(name)
      erb_node = create_erb_output_node(ruby_variable)
      value_node = create_html_attribute_value_node([erb_node])

      create_html_attribute_node(name_node, value_node)
    end

    def create_html_attribute_name_node(name)
      name_literal = create_literal_node(name)

      Herb::AST::HTMLAttributeNameNode.new("HTMLAttributeNameNode", dummy_location, [], [name_literal])
    end

    def create_literal_node(string)
      Herb::AST::LiteralNode.new("LiteralNode", dummy_location, [], string.dup)
    end

    def create_html_attribute_node(name_node, value_node)
      equals_token = create_token(:equals, "=")

      Herb::AST::HTMLAttributeNode.new("HTMLAttributeNode", dummy_location, [], name_node, equals_token, value_node)
    end

    def create_html_attribute_value_node(children)
      Herb::AST::HTMLAttributeValueNode.new(
        "HTMLAttributeValueNode",
        dummy_location,
        [],
        create_token(:quote, '"'),
        children,
        create_token(:quote, '"'),
        true
      )
    end

    def create_erb_content_node(ruby_code, tag_opening)
      tag_opening = create_token(:erb_tag_opening, tag_opening)
      content = create_token(:erb_content, " #{ruby_code} ")
      tag_closing = create_token(:erb_tag_closing, "%>")

      Herb::AST::ERBContentNode.new(
        "ERBContentNode",
        dummy_location,
        [],
        tag_opening,
        content,
        tag_closing,
        nil,   # analyzed_ruby
        true,  # parsed
        true   # valid
      )
    end

    def create_erb_code_node(ruby_code)
      create_erb_content_node(ruby_code, "<%")
    end

    def create_erb_output_node(ruby_code)
      create_erb_content_node(ruby_code, "<%=")
    end

    def create_token(type, value)
      Herb::Token.new(value.dup, dummy_range, dummy_location, type.to_s)
    end

    def dummy_location
      @dummy_location ||= Herb::Location.from(0, 0, 0, 0)
    end

    def dummy_range
      @dummy_range ||= Herb::Range.from(0, 0)
    end
  end
end

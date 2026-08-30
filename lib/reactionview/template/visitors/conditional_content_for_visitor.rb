# frozen_string_literal: true

require "herb/engine/visitors/content_for_visitor"

module ReActionView
  class Template
    module Visitors
      # Emits content behind a render-time condition, so a cached compiled
      # template can still decide per request. +condition+ is Ruby source
      # evaluated in the view context and must never come from user input.
      class ConditionalContentForVisitor < ::Herb::Engine::ContentForVisitor
        #: (String?, tag_name: String, condition: String, ?attributes: Hash[untyped, untyped]) -> void
        def initialize(content, tag_name:, condition:, attributes: {})
          super(content, tag_name: tag_name, attributes: attributes)

          @condition = condition
        end

        private

        #: () -> Herb::AST::RubyLiteralNode
        def content_node
          ::Herb::AST::RubyLiteralNode.build(
            content: "((#{@condition}) ? #{@content.dump}.html_safe : \"\")"
          )
        end
      end
    end
  end
end

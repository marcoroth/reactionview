# frozen_string_literal: true

require "erb"
require "pathname"

module ReActionView
  module Phlex
    # Outlines Phlex components in the Herb dev tools, the way ERB templates already are.
    #
    # The dev tools do not ask the server what a piece of the page is. They read the
    # `data-herb-debug-*` attributes on the HTML, and those are written by the Herb debug
    # visitor while it compiles a template. A component written only in Ruby never goes
    # through that compiler, so it never gets them and stays invisible in the
    # "Component Outlines".
    #
    # Including this module writes the same attributes on the first tag a component
    # renders, while debug mode is on. When that tag already carries them, because the
    # component starts by rendering another one, the inner component keeps its outline.
    #
    #     class Components::Base < Phlex::HTML
    #       include ReActionView::Phlex::ComponentOutlines
    #     end
    #
    module ComponentOutlines
      ROOT_TAG = %r{<(?![!/])[a-zA-Z][\w-]*} #: Regexp
      OUTLINE_TYPE_ATTRIBUTE = "data-herb-debug-outline-type" #: String

      private

      #: () { () -> void } -> void
      def around_template
        return super unless ::ReActionView.config.debug_mode_enabled?

        buffer = @_state.buffer
        template_start = buffer.length

        super

        outline_root_tag(buffer, template_start)
      end

      #: (String, Integer) -> void
      def outline_root_tag(buffer, template_start)
        root_tag = ROOT_TAG.match(buffer, template_start)
        return if root_tag.nil? || outlined?(buffer, root_tag.end(0))

        buffer.insert(root_tag.end(0), outline_attributes)
      end

      #: (String, Integer) -> bool
      def outlined?(buffer, tag_name_end)
        tag_end = buffer.index(">", tag_name_end) || buffer.length

        buffer[tag_name_end...tag_end].include?(OUTLINE_TYPE_ATTRIBUTE)
      end

      #: () -> String
      def outline_attributes
        full_path = self.class.instance_method(:view_template).source_location.first

        {
          OUTLINE_TYPE_ATTRIBUTE => "component",
          "data-herb-debug-file-name" => self.class.name,
          "data-herb-debug-file-relative-path" => outline_relative_path(full_path),
          "data-herb-debug-file-full-path" => full_path,
        }.map { |name, value| %( #{name}="#{::ERB::Util.html_escape(value)}") }.join
      end

      #: (String) -> String
      def outline_relative_path(full_path)
        ::Herb::Visitor::Context.derive_relative_file_path(::Pathname.new(full_path), ::Pathname.new(::ReActionView.config.project_path))
      end
    end
  end
end

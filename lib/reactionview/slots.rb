# frozen_string_literal: true

module ReActionView
  # Serving what a template's dynamic parts evaluated to, for a client that already has its markup.
  #
  # The browser holds an index of the slot markers a page was rendered with, so a state change costs
  # the values that changed rather than the page. This is the half that answers with them.
  module Slots
    FORMAT = :slots #: Symbol
    MIME_TYPE = "application/vnd.herb.slots+json" #: String
    REGION_MARKER = "herb-region:" #: String

    class << self
      # Builds the map of what a page's state reaches.
      #
      # Held for the process because it reads and compiles every template a page renders, and a
      # page asks for the same answer on every request. Reset when the config changes underneath
      # it, which in development is what a reload does.
      #: () -> untyped
      def dependencies
        root = ReActionView.config.project_path

        @dependencies = nil if @root != root
        @root = root
        @dependencies ||= ::Herb::Engine::SlotDependencies.new(
          root,
          compile: ->(source, path) { ReActionView::Template::Handlers::Herb.compile_for_dependencies(source, path) }
        )
      end

      #: () -> void
      def reset_dependencies!
        @dependencies = nil
      end
    end
  end
end

# frozen_string_literal: true

module ReActionView
  module Slots
    # Compiles one template for the Herb dev server, the way the application would.
    #
    # The dev server's watcher calls this from its own thread whenever a template changes, so
    # the compile runs inside the Rails executor for autoload and reloader safety. A raise is
    # left to the caller, which turns it into diagnostics instead of crashing the thread.
    #
    class DevCompiler
      def call(source, relative_path)
        absolute = File.expand_path(relative_path, ReActionView.config.project_path)

        result = Rails.application.executor.wrap do
          ReActionView::Template::Handlers::Herb.compile_for_schema(source, absolute)
        end

        ReActionView::Slots.reset_dependencies!

        result
      end
    end
  end
end

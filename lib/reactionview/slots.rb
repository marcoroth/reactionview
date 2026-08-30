# frozen_string_literal: true

module ReActionView
  module Slots
    FORMAT = :slots #: Symbol
    MIME_TYPE = "application/vnd.herb.slots+json" #: String
    REGION_MARKER = "herb-region:" #: String

    #: () -> untyped
    def self.dependencies
      root = ReActionView.config.project_path

      @dependencies = nil if @root != root
      @root = root
      @dependencies ||= ::Herb::Engine::Slots::Dependencies.new(
        root,
        compile: ->(source, path) { ReActionView::Template::Handlers::Herb.compile_for_dependencies(source, path) }
      )
    end

    #: () -> void
    def self.reset_dependencies!
      @dependencies = nil
    end
  end
end

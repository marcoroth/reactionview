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

    #: (String, Integer) -> String?
    def self.block_program(path, index)
      mtime = ::File.mtime(path)
      key = [path, index, mtime]

      (@block_programs_lock ||= ::Mutex.new).synchronize do
        programs = (@block_programs ||= {})
        programs.clear if programs.size > 128 && !programs.key?(key)
        programs[key] ||= ReActionView::Template::Handlers::Herb.compile_for_block(::File.read(path), path, index)
      end
    end
  end
end

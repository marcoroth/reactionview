# frozen_string_literal: true

module ReActionView
  class Template
    class Dependencies
      def self.current
        @current ||= new
      end

      def self.reset!
        @current = nil
      end

      def engine_roots
        @engine_roots ||= engines.filter_map { |engine| directory(engine.root) }
      end

      def gem_paths_outside(app_root)
        return [] unless app_root

        gem_paths.reject { |path| app_root.start_with?(path) }
      end

      def app_view_paths
        @app_view_paths ||= (registered_view_paths - engine_view_paths).filter_map { |path| directory(path) }
      end

      def view_paths
        @view_paths ||= registered_view_paths.filter_map { |path| directory(path) }
      end

      private

      def gem_paths
        @gem_paths ||= begin
          specs = defined?(::Gem) && ::Gem.respond_to?(:loaded_specs) ? ::Gem.loaded_specs.values : []

          specs.filter_map { |spec| directory(spec.full_gem_path) }
        end
      end

      def engines
        return [] unless defined?(::Rails::Engine)

        @engines ||= ::Rails::Engine.subclasses.filter_map { |klass| engine_instance(klass) }
      end

      def engine_instance(klass)
        return nil unless klass.respond_to?(:instance)

        engine = klass.instance

        return nil if engine.nil? || engine == application
        return nil unless engine.respond_to?(:root) && engine.root

        engine
      rescue StandardError
        nil
      end

      def engine_view_paths
        engines.flat_map do |engine|
          engine.paths["app/views"].existent
        rescue StandardError
          []
        end
      end

      def registered_view_paths
        return [] unless defined?(::ActionController::Base)

        ::ActionController::Base.view_paths.filter_map { |resolver| resolver.path if resolver.respond_to?(:path) }
      rescue StandardError
        []
      end

      def application
        ::Rails.application if defined?(::Rails) && ::Rails.respond_to?(:application)
      end

      def directory(path)
        return nil if path.nil?

        expanded = File.expand_path(path.to_s)

        expanded.empty? ? nil : "#{expanded.chomp("/")}/"
      end
    end
  end
end

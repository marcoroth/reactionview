# frozen_string_literal: true

module ReActionView
  class Template
    module LocalTemplate
      FRAMEWORK_TEMPLATE_SEGMENT = "/action_dispatch/middleware/templates/" #: String

      private

      def framework_template?(template)
        return false unless template.respond_to?(:identifier) && template.identifier

        template.identifier.to_s.include?(FRAMEWORK_TEMPLATE_SEGMENT)
      end

      def local_template?(template)
        identifier = template_identifier(template)

        return true unless identifier

        app_root = application_root
        dependencies = Dependencies.current

        return false if under?(identifier, dependencies.engine_roots)
        return false if under?(identifier, dependencies.gem_paths_outside(app_root))
        return true if under?(identifier, dependencies.app_view_paths)
        return true unless app_root

        under?(identifier, [app_root])
      end

      def template_identifier(template)
        return nil unless template.respond_to?(:identifier)

        identifier = template.identifier

        return nil if identifier.nil? || identifier.to_s.empty?

        File.expand_path(identifier.to_s)
      end

      def application_root
        return nil unless defined?(::Rails) && ::Rails.respond_to?(:root) && ::Rails.root

        "#{File.expand_path(::Rails.root.to_s).chomp("/")}/"
      end

      def under?(identifier, prefixes)
        prefixes.any? { |prefix| identifier.start_with?(prefix) }
      end
    end
  end
end

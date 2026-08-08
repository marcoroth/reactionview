# frozen_string_literal: true

module ReActionView
  class Template
    module LocalTemplate
      private

      def local_template?(template)
        return true unless template.respond_to?(:identifier) && template.identifier
        return false if vendored_template?(template)

        template.identifier.start_with?(Rails.root.to_s)
      end

      def vendored_template?(template)
        return false unless defined?(Bundler)

        template.identifier.start_with?(Bundler.bundle_path.to_s)
      end
    end
  end
end

# frozen_string_literal: true

module ReActionView
  class Template
    module Handlers
      class ERB < ActionView::Template::Handlers::ERB
        autoload :Herb, "reactionview/template/handlers/herb/herb"

        def call(template, source)
          if intercept_template?(template)
            ::ReActionView::Template::Handlers::Herb.call(template, source)
          else
            super
          end
        end

        private

        def intercept_template?(template)
          template.format == :html && ReActionView.config.intercept_erb && local_template?(template)
        end

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
end

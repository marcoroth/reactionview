# frozen_string_literal: true

module ReActionView
  class Template
    module Handlers
      class ERB < ActionView::Template::Handlers::ERB
        include ReActionView::Template::LocalTemplate

        autoload :Herb, "reactionview/template/handlers/herb/herb"

        def call(template, source)
          return super unless intercept_template?(template)

          ::ReActionView::Template::Handlers::Herb.call(template, source)
        rescue StandardError => e
          raise unless fall_back_to_erb?(template)

          log_external_template_error(template, e)

          super
        end

        private

        def intercept_template?(template)
          return false unless template.format == :html && ReActionView.config.intercept_erb

          local_template?(template) || ReActionView.config.external_template_mode != :skip
        end

        def fall_back_to_erb?(template)
          !local_template?(template) && ReActionView.config.external_template_mode == :fallback
        end

        def log_external_template_error(template, error)
          return unless defined?(Rails.logger) && Rails.logger

          Rails.logger.warn(
            "[ReActionView] #{template.identifier} could not be compiled by Herb, " \
            "falling back to ActionView::Template::Handlers::ERB: #{error.message.strip.lines.first}"
          )
        end
      end
    end
  end
end

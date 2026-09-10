# frozen_string_literal: true

module ReActionView
  class Template
    module Handlers
      class ERB < ActionView::Template::Handlers::ERB
        include ReActionView::Template::LocalTemplate

        INTERCEPTED_FORMATS = [:html, ::ReActionView::Slots::FORMAT].freeze

        autoload :Herb, "reactionview/template/handlers/herb/herb"

        def call(template, source)
          if skip_external_template?(template)
            @erb_fallback = true

            return super
          end

          return super unless intercept_template?(template)

          ::ReActionView::Template::Handlers::Herb.call(
            template, source, validation_mode: herb_validation_mode(template)
          )
        rescue ::Herb::Engine::CompilationError, StandardError => e
          raise unless fall_back_to_erb?(template)

          log_external_template_error(template, e)

          @erb_fallback = true

          super
        end

        private

        def implementation_for(template)
          return self.class.erb_implementation if @erb_fallback

          super
        end

        def skip_external_template?(template)
          return false unless INTERCEPTED_FORMATS.include?(template.format) && ReActionView.config.intercept_erb
          return false if framework_template?(template) || local_template?(template)

          ReActionView.config.external_template_mode == :skip
        end

        def intercept_template?(template)
          return false unless INTERCEPTED_FORMATS.include?(template.format) && ReActionView.config.intercept_erb
          return false if framework_template?(template)

          local_template?(template) || ReActionView.config.external_template_mode != :skip
        end

        def herb_validation_mode(template)
          return nil if local_template?(template)
          return nil unless ReActionView.config.external_template_mode == :fallback

          :raise
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

# frozen_string_literal: true

module ReActionView
  module Template
    module Handlers
      class ERB
        def call(template, source = nil)
          source ||= template.source

          # Pre-render Herb validation
          if ReActionView.config.enable_herb_validation
            ReActionView::Validator.validate_template_file(template.identifier)
          end

          # Process with ReactionView template engine
          engine = ReActionView::TemplateEngine.new(
            source,
            escape: true,
            trim: false,
            template_path: template.identifier
          )

          engine.src
        end
      end
    end
  end
end

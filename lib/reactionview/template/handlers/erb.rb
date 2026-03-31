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

          template.identifier.start_with?(Rails.root.to_s)
        end
      end
    end
  end
end

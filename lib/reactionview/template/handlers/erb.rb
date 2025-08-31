# frozen_string_literal: true

module ReActionView
  class Template
    module Handlers
      class ERB < ActionView::Template::Handlers::ERB
        autoload :Herb, "reactionview/template/handlers/herb/herb"

        def call(template, source)
          if template.format == :html && ReActionView.config.intercept_erb
            ::ReActionView::Template::Handlers::Herb.call(template, source)
          else
            super
          end
        end
      end
    end
  end
end

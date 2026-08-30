# frozen_string_literal: true

require "json"

module ReActionView
  module Slots
    module Rendering
      def _normalize_options(options)
        super

        options[:layout] = false if slots_request?

        options
      end

      def render_to_body(options = {})
        rendered = super

        rendered.is_a?(::Hash) ? ::JSON.generate(rendered) : rendered
      end

      private

      def slots_request?
        respond_to?(:request) && request&.format&.symbol == Slots::FORMAT
      end
    end
  end
end

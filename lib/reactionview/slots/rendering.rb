# frozen_string_literal: true

require "json"

module ReActionView
  module Slots
    module Rendering
      BODY_END_TAG = "</body>"

      def _normalize_options(options)
        super

        options[:layout] = false if slots_request?

        options
      end

      def render_to_body(options = {})
        rendered = super

        return ::JSON.generate(rendered) if rendered.is_a?(::Hash)

        deliver_slot_dependencies(rendered, options)

        rendered
      end

      private

      def slots_request?
        respond_to?(:request) && request&.format&.symbol == Slots::FORMAT
      end

      def deliver_slot_dependencies(body, options)
        return if slots_request?
        return unless body.is_a?(::String)
        return unless body.include?(Slots::REGION_MARKER)

        entry = entry_point_for(options)

        return unless entry

        Slots.dependencies.deliver(entry)
      rescue ::StandardError => e
        logger = defined?(::Rails) && ::Rails.logger
        logger&.debug { "ReActionView could not build the slot dependency map: #{e.class}: #{e.message}" }

        nil
      end

      def entry_point_for(options)
        name = options[:template] || (respond_to?(:action_name) ? action_name : nil)

        return nil unless name

        template = lookup_context.find(name.to_s, options[:prefixes] || _prefixes, false)

        template&.identifier
      rescue ::ActionView::MissingTemplate
        nil
      end
    end
  end
end

# frozen_string_literal: true

module ReActionView
  module Slots
    class Resolver < ActionView::FileSystemResolver
      def find_all(name, prefix = nil, partial = false, details = {}, key = nil, locals = [])
        return [] unless slots_first?(details, key)

        super
      end

      # Rails 8.2 resolves a single template through `find`, which no longer goes through `find_all`.
      def find(name, prefix = nil, partial = false, details = {}, key = nil, locals = [])
        return nil unless slots_first?(details, key)

        super
      end

      private

      def slots_first?(details, key)
        requested = key || ActionView::TemplateDetails::Requested.new(**details)

        requested.formats_idx[Slots::FORMAT]&.zero?
      end

      def build_unbound_template(template)
        unbound = super
        details = unbound.details

        return unbound unless details.format == :html

        ActionView::UnboundTemplate.new(
          source_for_template(template),
          template,
          details: ActionView::TemplateDetails.new(details.locale, details.handler, Slots::FORMAT, details.variant),
          virtual_path: unbound.virtual_path
        )
      end

      def unbound_templates_from_path(path)
        super.select { |unbound| unbound.format == Slots::FORMAT }
      end
    end
  end
end

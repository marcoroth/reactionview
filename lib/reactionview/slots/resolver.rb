# frozen_string_literal: true

module ReActionView
  module Slots
    class Resolver < ActionView::FileSystemResolver
      private

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

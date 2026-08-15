# frozen_string_literal: true

module ReActionView
  module Slots
    # Finds a template for a request that asked for values rather than markup.
    #
    # ActionView finds a template by its format, and there is no `show.slots.erb` on disk to find.
    # There should not be one either: the values a template produces are the same template, compiled
    # to answer a different question, and a second file would be the first one's markup written out
    # twice and free to drift from it.
    #
    # So this resolves the `.html.erb` already there and hands it back saying its format is `:slots`.
    # The handler reads that and compiles the values. One file, one set of markers, one numbering.
    #
    # It resolves nothing else. Prepended to the view paths it sits in front of the resolver Rails
    # built, and an `:html` request falls straight through, because a template whose details say
    # `:slots` matches no other format.
    class Resolver < ActionView::FileSystemResolver
      LAYOUTS = "layouts/"

      private

      def build_unbound_template(template)
        unbound = super
        details = unbound.details

        return unbound unless details.format == :html
        return unbound if unbound.virtual_path.start_with?(LAYOUTS)

        ActionView::UnboundTemplate.new(
          source_for_template(template),
          template,
          details: ActionView::TemplateDetails.new(details.locale, details.handler, Slots::FORMAT, details.variant),
          virtual_path: unbound.virtual_path
        )
      end

      # A layout has values of its own and no business carrying the action's, since it is rendered
      # around them and would be the outermost payload rather than the one that was asked for.
      # Dropping everything this did not convert is what keeps it out, along with every other format.
      def unbound_templates_from_path(path)
        super.select { |unbound| unbound.format == Slots::FORMAT }
      end
    end
  end
end

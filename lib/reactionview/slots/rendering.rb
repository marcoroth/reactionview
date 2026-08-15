# frozen_string_literal: true

require "json"

module ReActionView
  module Slots
    # Turns the values a template compiled to into the body of a response.
    #
    # A template compiled for `:slots` returns a Hash rather than a String, and every layer below
    # here expects a body it can write out. Rack takes anything that responds to `each`, so a Hash
    # arriving unserialized is not an error: it is iterated into its `[key, value]` pairs and
    # written out one pair at a time. The response is nonsense and nothing raises.
    #
    # So the Hash is serialized here, at the point where it stops being a value and becomes bytes,
    # rather than in the compiled template, which would leave nothing to nest a partial's values in.
    module Rendering
      # A values response is the action's template and nothing around it.
      #
      # A layout is chrome: it renders the same on every request, so its values are the ones least
      # worth sending, and rendering it means rendering every partial in it. It is also where
      # `content_for` lives, which is the one thing that breaks the addressing, since content is
      # rendered where it is written and appears where it is yielded, and the payload would say the
      # former while the page says the latter.
      #
      # Anything outside the action that does need updating is a region of its own on the page and
      # can be asked for by name, rather than by rendering the page around it.
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

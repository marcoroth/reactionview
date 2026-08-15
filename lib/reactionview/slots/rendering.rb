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
      def render_to_body(options = {})
        rendered = super

        rendered.is_a?(::Hash) ? ::JSON.generate(rendered) : rendered
      end
    end
  end
end

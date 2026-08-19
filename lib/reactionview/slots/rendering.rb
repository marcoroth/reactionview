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
      BODY_END_TAG = "</body>"
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

      # A page carries the map of what its state reaches, so a client knows which slots a change
      # touches before it asks.
      #
      # The map spans a render tree and not one template, so it is built from the template the
      # action rendered and delivered once for the page, which is why it is put in here and not by
      # a visitor. A visitor sees one template being compiled and cannot know which of them a
      # request started at.
      #
      # A page with no markers gets nothing. That is the same question as whether slots are on for
      # this template, answered by looking at what was rendered instead of asking the config, since
      # a template can opt in on its own with a directive.
      def render_to_body(options = {})
        rendered = super

        return ::JSON.generate(rendered) if rendered.is_a?(::Hash)

        with_slot_dependencies(rendered, options)
      end

      private

      def slots_request?
        respond_to?(:request) && request&.format&.symbol == Slots::FORMAT
      end

      def with_slot_dependencies(body, options)
        return body if slots_request?
        return body unless body.is_a?(::String)
        return body unless body.include?(Slots::REGION_MARKER)

        entry = entry_point_for(options)

        return body unless entry

        element = Slots.dependencies.element(entry)

        return body if element.empty?

        body.sub(BODY_END_TAG) { |tag| "#{element}#{tag}" }
      rescue ::StandardError => error
        ReActionView.logger&.debug { "ReActionView could not build the slot dependency map: #{error.class}: #{error.message}" }

        body
      end

      # The action's own template, which is where the map's walk starts. Everything the page
      # renders below it is reached from there.
      def entry_point_for(options)
        name = options[:template] || (respond_to?(:action_name) ? action_name : nil)

        return nil unless name

        template = lookup_context.find_template(name.to_s, options[:prefixes] || _prefixes, false)

        template&.identifier
      rescue ::ActionView::MissingTemplate
        nil
      end
    end
  end
end

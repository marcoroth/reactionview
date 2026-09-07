# frozen_string_literal: true

require "json"

module ReActionView
  module Slots
    module Rendering
      BODY_END_TAG = "</body>"
      BLOCK_HEADER = "Herb-Block"

      def _normalize_options(options)
        super

        options[:layout] = false if slots_request?

        options
      end

      def render_to_body(options = {})
        protect_steered_response

        if (block = scoped_block_index)
          begin
            return ::JSON.generate(render_scoped_block(block, options))
          rescue ::StandardError => e
            raise unless ReActionView.config.development?

            return render_slots_error(e)
          end
        end

        begin
          rendered = super
        rescue ::StandardError => e
          raise unless slots_request? && ReActionView.config.development?

          return render_slots_error(e)
        end

        return ::JSON.generate(merge_schema(rendered, options)) if rendered.is_a?(::Hash)

        deliver_slot_dependencies(rendered, options)

        rendered
      end

      private

      def protect_steered_response
        return unless slots_request?
        return unless request.respond_to?(:headers) && respond_to?(:response) && response
        return if request.headers[StateOverrides::HEADER].nil?

        response.headers["Cache-Control"] = "no-store"
      end

      def render_slots_error(error)
        self.status = 500

        cause = error.cause || error
        template = error.respond_to?(:template) && error.template

        entry = {
          class: cause.class.name,
          message: cause.message,
          template: template.respond_to?(:short_identifier) ? template.short_identifier : nil,
          backtrace: cleaned_backtrace(cause),
        }

        ::JSON.generate({ error: entry })
      end

      def cleaned_backtrace(cause)
        raw = cause.backtrace || []
        cleaned = ::Rails.backtrace_cleaner.clean(raw)

        (cleaned.empty? ? raw : cleaned).first(5)
      end

      def merge_schema(rendered, options)
        return rendered unless request&.headers&.[]("Herb-Schema").present?

        entry = entry_point_for(options)

        return rendered unless entry

        schema = ReActionView::Template::Handlers::Herb.compile_for_schema(::File.read(entry), entry)

        rendered.merge(schema: {
          mode: schema.mode,
          version: schema.version,
          manifest: schema.manifest,
          static_markup: schema.static_markup,
          statics: schema.statics,
        })
      rescue ::StandardError => e
        logger = defined?(::Rails) && ::Rails.logger
        logger&.debug { "ReActionView could not build the schema envelope: #{e.class}: #{e.message}" }

        rendered
      end

      def scoped_block_index
        return nil unless slots_request?

        value = request.headers[BLOCK_HEADER]

        value&.match?(/\A\d+\z/) ? Integer(value, 10) : nil
      end

      def render_scoped_block(index, options)
        entry = entry_point_for(options)

        raise ::ArgumentError, "a scoped block request found no entry template" unless entry

        program = ReActionView::Slots.block_program(entry, index)

        raise ::ArgumentError, "the entry template compiles no slots, so it holds no block \#{index}" unless program

        view_context.instance_eval(program, entry)
      end

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

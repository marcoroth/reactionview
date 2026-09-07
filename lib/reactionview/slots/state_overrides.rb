# frozen_string_literal: true

require "json"

module ReActionView
  module Slots
    # Parses the `Herb-State` request header a client sends with a values request.
    #
    # The header carries the client's state so the compiled values program evaluates
    # the branches the client is showing. The parse is lenient on purpose, since a
    # malformed or oversized header must degrade to the compiled defaults and never
    # break a render.
    #
    module StateOverrides
      HEADER = "Herb-State" #: String
      MAX_BYTES = 8192 #: Integer

      #: (String?) -> Hash[String, Hash[String, untyped]]?
      def self.parse(header_value)
        return nil if header_value.nil? || header_value.strip.empty?
        return nil if header_value.bytesize > MAX_BYTES

        raw = ::JSON.parse(header_value)

        return nil unless raw.is_a?(::Hash)

        overrides = raw.select { |key, value| key.is_a?(::String) && value.is_a?(::Hash) }

        overrides.empty? ? nil : overrides
      rescue ::JSON::ParserError
        nil
      end
    end

    module StateOverridesHelper
      #: () -> Hash[String, Hash[String, untyped]]?
      def __herb_state_overrides
        return @__herb_state_overrides if defined?(@__herb_state_overrides)

        header = respond_to?(:request) && request ? request.headers[StateOverrides::HEADER] : nil

        @__herb_state_overrides = StateOverrides.parse(header)
      end

      #: (?String?, ?untyped) -> untyped
      def herb_state(name = nil, default = nil)
        overrides = __herb_state_overrides

        return overrides if name.nil?
        return default if overrides.nil?

        overrides.each_value do |states|
          return states[name] if states.key?(name)
        end

        default
      end
    end
  end
end

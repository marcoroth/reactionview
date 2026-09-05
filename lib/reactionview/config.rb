# frozen_string_literal: true

module ReActionView
  class Config
    EXTERNAL_TEMPLATE_MODES = %i[fallback skip compile].freeze
    SLOT_MODES = %i[server client].freeze

    attr_accessor :intercept_erb
    attr_accessor :debug_mode
    attr_accessor :transform_visitors

    attr_reader :slots

    attr_writer :dev_server
    attr_writer :dev_server_port
    attr_writer :project_path
    attr_writer :validation_mode

    def initialize
      @intercept_erb = false
      @debug_mode = nil
      @dev_server = nil
      @dev_server_port = nil
      @external_template_mode = nil
      @transform_visitors = []
      @project_path = nil
      @slots = false
      @instrumentation = nil
    end

    def dev_server_enabled?
      return @dev_server unless @dev_server.nil?

      true
    end

    def slots=(value)
      unless [nil, true, false].include?(value) || SLOT_MODES.include?(value)
        raise ArgumentError, "slots must be true, false, or one of #{SLOT_MODES.inspect}, got #{value.inspect}"
      end

      @slots = value
    end

    def slot_mode_for(source)
      ::Herb::Engine::Slots::Visitor.directive_mode(source) || default_slot_mode
    end

    def default_slot_mode
      return nil unless slots

      slots == true ? :server : slots
    end

    def external_template_mode
      @external_template_mode || :fallback
    end

    def external_template_mode=(mode)
      unless mode.nil? || EXTERNAL_TEMPLATE_MODES.include?(mode)
        raise ArgumentError, "external_template_mode must be one of :fallback, :skip, or :compile, got #{mode.inspect}"
      end

      @external_template_mode = mode
    end

    def project_path
      @project_path || Rails.root.to_s
    end

    def validation_mode
      return @validation_mode unless @validation_mode.nil?

      test? ? :raise : :overlay
    end

    def development?
      defined?(Rails) && Rails.env.development?
    end

    def production?
      defined?(Rails) && Rails.env.production?
    end

    def test?
      defined?(Rails) && Rails.env.test?
    end

    def debug_mode_enabled?
      return @debug_mode unless @debug_mode.nil?

      development?
    end

    def instrumentation
      @instrumentation ||= InstrumentationOptions.new(enabled: development?)
    end

    class InstrumentationOptions < ::ActiveSupport::OrderedOptions
      BUILT_INS = [:sql_queries, :render_times, :translations].freeze
      KEYS = ([:enabled] + BUILT_INS).freeze

      def initialize(enabled:)
        super()

        merge!(enabled: enabled, **BUILT_INS.to_h { |key| [key, true] })
      end

      def []=(key, value)
        raise ArgumentError, "unknown instrumentation option #{key.inspect}, expected one of #{KEYS.inspect}" unless KEYS.include?(key.to_sym)

        super
      end

      def measuring?(built_in)
        !!self[:enabled] && !!self[built_in]
      end
    end

    def dev_server_port
      return @dev_server_port if @dev_server_port
      return nil unless development?

      require "herb/dev/server_entry"

      ::Herb::Dev::ServerEntry.port_for(Rails.root.to_s)
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end
end

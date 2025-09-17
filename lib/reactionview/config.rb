# frozen_string_literal: true

module ReActionView
  class Config
    attr_accessor :intercept_erb
    attr_accessor :debug_mode
    attr_accessor :transform_visitors

    def initialize
      @intercept_erb = false
      @debug_mode = nil
      @transform_visitors = []
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
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end
end

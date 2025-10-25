# frozen_string_literal: true

module ReActionView
  class Config
    attr_accessor :intercept_erb
    attr_accessor :debug_mode
    attr_accessor :transform_visitors
    attr_accessor :show_render_times

    def initialize
      @intercept_erb = false
      @debug_mode = nil
      @transform_visitors = []
      @show_render_times = nil
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

    def show_render_times?
      return @show_render_times unless @show_render_times.nil?

      debug_mode_enabled?
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end
end

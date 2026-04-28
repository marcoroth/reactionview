# frozen_string_literal: true

module ReActionView
  class Config
    attr_accessor :intercept_erb
    attr_accessor :debug_mode
    attr_accessor :dev_server_port
    attr_accessor :transform_visitors
    attr_writer :validation_mode

    def initialize
      @intercept_erb = false
      @debug_mode = nil
      @dev_server_port = nil
      @transform_visitors = []
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

    def dev_server_port
      return @dev_server_port if @dev_server_port
      return nil unless development?

      project_path = defined?(Rails) ? Rails.root.to_s : Dir.pwd
      Herb.dev_server_port(project_path)
    rescue StandardError
      nil
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end
end

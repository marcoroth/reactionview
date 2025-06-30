# frozen_string_literal: true

module ReActionView
  class Config
    attr_accessor :template_exclusion_filter, :enable_herb_validation, :enable_html5_validation, :verbose_error_logging, :inject_development_errors, :strict_validation

    def initialize
      @template_exclusion_filter = nil
      @enable_herb_validation = true
      @enable_html5_validation = true
      @verbose_error_logging = false
      @inject_development_errors = true
      @strict_validation = false
    end

    def development_mode?
      defined?(Rails) && Rails.env.development?
    end

    def should_inject_errors?
      @inject_development_errors && development_mode?
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end
end

# frozen_string_literal: true

module ReActionView
  class ValidationError < StandardError
    attr_reader :errors, :template_path

    def initialize(errors, template_path)
      @errors = errors
      @template_path = template_path
      super(build_message)
    end

    private

    def build_message
      error_summary = @errors.map do |error|
        "#{error[:type]} Error: #{error[:message]} (Line #{error[:line]}, Column #{error[:column]})"
      end.join("\n")

      "Template validation failed in #{@template_path}:\n#{error_summary}"
    end
  end
end

# frozen_string_literal: true

require "herb"
require "nokogiri"

module ReActionView
  class Validator
    class << self
      def validate_template_file(file_path)
        return unless File.exist?(file_path)

        result = Herb.parse_file(file_path)
        log_errors("Pre-render validation", file_path, result) if result.errors.any?
        result
      rescue => e
        log_exception("Pre-render validation", file_path, e)
        nil
      end

      def validate_rendered_content(content, template_path = nil)
        validation_errors = []

        # Herb validation
        herb_result = Herb.parse(content)
        if herb_result.errors.any?
          log_errors("Post-render Herb validation", template_path, herb_result)
          validation_errors.concat(format_herb_errors(herb_result.errors))
        end

        # HTML5 validation with Nokogiri
        if ReActionView.config.enable_html5_validation
          html5_result = validate_html5(content, template_path)
          if html5_result&.errors&.any?
            validation_errors.concat(format_html5_errors(html5_result.errors))
          end
        end

        # Return validation result with errors for potential injection
        {
          herb_result: herb_result,
          validation_errors: validation_errors,
          content: content
        }
      rescue => e
        log_exception("Post-render validation", template_path, e)
        { herb_result: nil, validation_errors: [], content: content }
      end

      def validate_html5(content, template_path = nil)
        return unless content.strip.start_with?('<')

        document = Nokogiri::HTML5.parse(content, max_errors: 10)

        if document.errors.any?
          log_html5_errors("HTML5 validation", template_path, document.errors)
        end

        document
      rescue => e
        log_exception("HTML5 validation", template_path, e)
        nil
      end

      private

      def log_errors(stage, file_path, result)
        logger.error "[ReactionView::Validator] #{stage} errors in #{file_path || 'rendered content'}:"
        result.errors.each do |error|
          logger.error "  - #{error.message} at line #{error.location.start_line}, column #{error.location.start_column}"
        end
      end

      def log_html5_errors(stage, file_path, errors)
        logger.error "[ReactionView::Validator] #{stage} errors in #{file_path || 'rendered content'}:"
        errors.each do |error|
          logger.error "  - #{error.message} at line #{error.line}, column #{error.column}"
        end
      end

      def log_exception(stage, file_path, exception)
        logger.error "[ReactionView::Validator] #{stage} exception in #{file_path || 'rendered content'}: #{exception.message}"
        logger.error exception.backtrace.join("\n") if ReActionView.config.verbose_error_logging
      end

      def format_herb_errors(errors)
        errors.map do |error|
          {
            type: 'Herb',
            message: error.message,
            line: error.location.start_line,
            column: error.location.start_column
          }
        end
      end

      def format_html5_errors(errors)
        errors.map do |error|
          {
            type: 'HTML5',
            message: error.message,
            line: error.line,
            column: error.column
          }
        end
      end

      def logger
        @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      end
    end
  end
end

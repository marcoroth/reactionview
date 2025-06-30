# frozen_string_literal: true

require "erubi"

module ReActionView
  class TemplateEngine
    def initialize(input, options = {})
      @input = input
      @options = options
      @template_path = options[:template_path]
    end

    def src
      engine = Erubi::Engine.new(@input, @options)
      generated_code = engine.src

      # Add post-render validation hook if enabled
      if ReActionView.config.enable_herb_validation
        generated_code = add_post_render_validation(generated_code)
      end

      generated_code
    end

    private

    def add_post_render_validation(code)
      validation_code = <<~RUBY
        begin
          __original_result__ = (#{code.strip})
          if defined?(ReActionView::Validator)
            __validation_result__ = ReActionView::Validator.validate_rendered_content(__original_result__, #{@template_path.inspect})
            if __validation_result__[:validation_errors].any?
              if ReActionView.config.strict_validation
                raise ReActionView::ValidationError.new(__validation_result__[:validation_errors], #{@template_path.inspect})
              elsif ReActionView.config.should_inject_errors?
                __original_result__ = ReActionView::ErrorInjector.inject_errors(
                  __original_result__,
                  __validation_result__[:validation_errors],
                  #{@template_path.inspect}
                )
              end
            end
          end
          __original_result__
        rescue => __validation_error__
          Rails.logger.error "[ReactionView] Template validation failed: \#{__validation_error__.message}" if defined?(Rails)
          raise __validation_error__
        end
      RUBY

      validation_code
    end
  end
end

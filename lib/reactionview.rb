# frozen_string_literal: true

require_relative "reactionview/version"
require_relative "reactionview/config"
require_relative "reactionview/validation_error"
require_relative "reactionview/validator"
require_relative "reactionview/error_injector"
require_relative "reactionview/template_engine"
require_relative "reactionview/template_handler"
require_relative "reactionview/template/handlers/erb"
require_relative "reactionview/template/handlers/herb"

if defined?(Rails::Railtie)
  require_relative "reactionview/railtie"
end

module ReActionView
  class << self
    def register_content_type(extension, implementation)
      TemplateHandler.content_types[extension] = implementation
    end
  end
end

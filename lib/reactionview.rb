# frozen_string_literal: true

require_relative "reactionview/version"
require_relative "reactionview/config"

# require_relative "reactionview/validation_error"
# require_relative "reactionview/syntax_error_handler"
# require_relative "reactionview/validator"
# require_relative "reactionview/error_injector"
# require_relative "reactionview/dependency_tracker"

# require_relative "reactionview/validations/validation_orchestrator"
# require_relative "reactionview/validations/herb_syntax_validation"
# require_relative "reactionview/validations/herb_document_validation"
# require_relative "reactionview/validations/herb_linter"
# require_relative "reactionview/validations/html5_validation"

# require_relative "reactionview/source_annotation_extractor"

require_relative "reactionview/template/handlers/erb"
require_relative "reactionview/template/handlers/herb"
require_relative "reactionview/template/handlers/herb/herb"

require_relative "reactionview/timing_visitor"
require_relative "reactionview/middleware/timing_output"

require_relative "reactionview/railtie" if defined?(Rails::Railtie)

module ReActionView
end

# frozen_string_literal: true

require "action_view"

module ReActionView
  class TemplateHandler
    cattr_accessor :content_types

    self.content_types = {
      "html.herb" => ReActionView::TemplateEngine,
    }

    class << self
      def prepend!
        ActionView::Template::Handlers::ERB.prepend(ConditionalImplementation)
      end
    end

    module ConditionalImplementation
      def call(template, source = nil)
        generate(template, source)
      end

      private

      def generate(template, source)
        source ||= template.source
        filename = template.identifier.split("/").last
        exts = filename.split(".")
        exts = exts[1..exts.length].join(".")

        # Pre-render Herb validation
        if ReActionView.config.enable_herb_validation
          ReActionView::Validator.validate_template_file(template.identifier)
        end

        template_source = source.dup.force_encoding(Encoding::ASCII_8BIT)
        erb = template_source.gsub(ActionView::Template::Handlers::ERB::ENCODING_TAG, "")
        encoding = Regexp.last_match(2)
        erb.force_encoding(valid_encoding(source.dup, encoding))
        erb.encode!

        excluded_template = !!ReActionView.config.template_exclusion_filter&.call(template.identifier)
        klass = ReActionView::TemplateHandler.content_types[exts] unless excluded_template
        klass ||= self.class.erb_implementation

        escape = self.class.escape_ignore_list.include?(template.type)

        options = {
          escape: escape,
          trim: (self.class.erb_trim_mode == "-"),
          template_path: template.identifier,
        }

        generator = klass.new(erb, **options)
        generator.src
      end
    end
  end
end

# frozen_string_literal: true

module ReActionView
  class Template
    module Handlers
      class Herb < ActionView::Template::Handlers::ERB
        autoload :Herb, "reactionview/template/handlers/herb/herb"

        class_attribute :erb_implementation, default: Handlers::Herb::Herb

        def call(template, source)
          visitors = []

          if ::ReActionView.config.debug_mode_enabled? && local_template?(template)
            visitors << ::Herb::Engine::DebugVisitor.new(
              file_path: template.identifier,
              project_path: Rails.root.to_s
            )
          end

          config = {
            filename: template.identifier,
            project_path: Rails.root.to_s,
            validation_mode: :overlay,
            content_for_head: reactionview_dev_tools_markup(template),
            visitors: visitors + ReActionView.config.transform_visitors,
          }

          erb_implementation.new(source, config).src
        end

        private

        def layout_template?(template)
          return false unless template.respond_to?(:identifier) && template.identifier

          template.identifier.include?("/layouts/")
        end

        def local_template?(template)
          return true unless template.respond_to?(:identifier) && template.identifier

          template.identifier.start_with?(Rails.root.to_s)
        end

        def active_support_editor
          return unless defined?(ActiveSupport::Editor)
          return if ActiveSupport::Editor.current.blank?

          ActiveSupport::Editor.current.instance_variable_get(:@url_pattern).split("://").first
        end

        def editor_meta_tag
          editor_name = active_support_editor || ENV["RAILS_EDITOR"] || ENV.fetch("EDITOR", nil)

          return if editor_name.blank?

          %(<meta name="herb-default-editor" content="#{editor_name}">)
        end

        def reactionview_dev_tools_markup(template)
          return nil unless layout_template?(template) && ::ReActionView.config.debug_mode_enabled?
          return nil unless local_template?(template)

          <<~HTML
            <meta name="herb-debug-mode" content="true">
            <meta name="herb-project-path" content="#{Rails.root}">
            #{editor_meta_tag}

            #{ActionController::Base.new.view_context.javascript_include_tag "reactionview-dev-tools.umd.js", defer: true}
          HTML
        end
      end
    end
  end
end

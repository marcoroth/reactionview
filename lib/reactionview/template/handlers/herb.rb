# frozen_string_literal: true

module ReActionView
  class Template
    module Handlers
      class Herb < ActionView::Template::Handlers::ERB
        include ReActionView::Template::LocalTemplate

        autoload :Herb, "reactionview/template/handlers/herb/herb"

        class_attribute :erb_implementation, default: Handlers::Herb::Herb

        def self.call(template, source, validation_mode: nil)
          new.call(template, source, validation_mode: validation_mode)
        end

        def call(template, source, validation_mode: nil)
          visitors = []

          if ::ReActionView.config.debug_mode_enabled? && local_template?(template)
            visitors << ::Herb::Engine::DebugVisitor.new(
              file_path: translate_path_for_editor(template.identifier),
              project_path: ::ReActionView.config.project_path
            )
          end

          config = {
            filename: template.identifier,
            project_path: Rails.root.to_s,
            validation_mode: validation_mode || ReActionView.config.validation_mode,
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

        def active_support_editor
          return unless defined?(ActiveSupport::Editor)
          return if ActiveSupport::Editor.current.blank?

          ActiveSupport::Editor.current.instance_variable_get(:@url_pattern).split("://").first
        end

        def translate_path_for_editor(template_path)
          rails_root = Rails.root.to_s
          project_path = ::ReActionView.config.project_path

          return template_path if project_path == rails_root

          template_path.to_s.sub(rails_root, project_path)
        end

        def editor_meta_tag
          editor_name = active_support_editor || ENV["RAILS_EDITOR"] || ENV.fetch("EDITOR", nil)

          return if editor_name.blank?

          %(<meta name="herb-default-editor" content="#{editor_name}">)
        end

        def dev_server_port_meta_tag
          port = ::ReActionView.config.dev_server_port

          return if port.blank?

          %(<meta name="herb-dev-server-port" content="#{port}">)
        end

        def reactionview_dev_tools_markup(template)
          return nil unless ::ReActionView.config.debug_mode_enabled?
          return nil unless layout_template?(template)
          return nil unless local_template?(template)

          <<~HTML
            <meta name="herb-debug-mode" content="true">
            <meta name="herb-project-path" content="#{Rails.root}">
            #{dev_server_port_meta_tag}
            #{editor_meta_tag}

            #{ActionController::Base.new.view_context.javascript_include_tag "reactionview-dev-tools.umd.js", defer: true}
            #{dismiss_hint_template}
          HTML
        end

        def dismiss_hint_template
          return unless ::ReActionView.config.validation_mode == :overlay

          <<~HTML.chomp
            <template data-herb-dismiss-hint>You can also disable this overlay by setting <code style="color: #ffeb3b; font-family: monospace; font-size: 12pt;">config.validation_mode = :none</code> in <code style="color: #ffeb3b; font-family: monospace; font-size: 12pt;">config/initializers/reactionview.rb</code>.</template>
          HTML
        end
      end
    end
  end
end

# frozen_string_literal: true

require "herb"
require "herb/engine"
require "herb/engine/dynamics_compiler"

# Visitors the engine does not load for itself. `Herb::Engine` stopped requiring the optional ones
# when they became opt-in, so anything that names one has to ask for it.
require "herb/engine/debug_visitor"
require "herb/engine/slot_visitor"
require "herb/engine/slot_dependencies"
require "herb/engine/content_for_visitor"
require "herb/engine/validators"

module ReActionView
  class Template
    module Handlers
      class Herb < ActionView::Template::Handlers::ERB
        include ReActionView::Template::LocalTemplate

        autoload :Herb, "reactionview/template/handlers/herb/herb"

        class_attribute :erb_implementation, default: Handlers::Herb::Herb

        # A value has to arrive escaped the way it would have been written, or the browser writes
        # different bytes into the page than the server would have. ActionView escapes on the way
        # into its buffer rather than in the compiled template, so the values compile has to do it
        # itself: `ERB::Util.h` escapes what `OutputBuffer#append=` escapes and leaves anything
        # already marked html_safe alone.
        #
        # Every context escapes the same way for the same reason. Herb would escape an attribute as
        # an attribute and a `<script>` as JavaScript, but ActionView does neither, so a `>` in an
        # attribute would come back escaped by one half and not the other.
        VALUES_ESCAPING = {
          escape: true,
          escapefunc: "::ERB::Util.h",
          attrfunc: nil,
          jsfunc: nil,
          cssfunc: nil,
        }.freeze

        def self.call(template, source, validation_mode: nil)
          new.call(template, source, validation_mode: validation_mode)
        end

        # The slot visitor a template is compiled with here, for anything that has to agree with
        # this compile about what a template's slots are.
        def self.compile_for_dependencies(source, path)
          new.send(:compile_for_dependencies, source, path)
        end

        def call(template, source, validation_mode: nil)
          mode = validation_mode || ReActionView.config.validation_mode

          # Everything the engine used to take as an option is a visitor on the stack now, so what
          # was configuration here is a list of what this template is compiled with.
          visitors = [
            *validation_visitors(mode),
            *debug_visitors(template),
            *head_visitors(template),
            *ReActionView.config.transform_visitors
          ]

          # `DebugVisitor` used to be told the path to write into its markers. It reads the one the
          # engine was compiled with now, so the translation for the editor has to be what the
          # engine is given, and the project path has to be the one it is relative to.
          config = {
            filename: translate_path_for_editor(template.identifier),
            project_path: ::ReActionView.config.project_path,
            visitors: visitors,
          }

          return values_source(template, source, config) if values_format?(template)

          config[:visitors] = [*visitors, *slot_visitors(template, source)]

          erb_implementation.new(source, config).src
        end

        private

        # The same template compiled to say what its slots evaluated to rather than to markup, for a
        # request that asked for values. Everything before the slot visitor is the stack the HTML
        # compile runs, because the numbering has to be over the same tree both times: a visitor
        # that adds a dynamic node to one and not the other moves every index after it.
        #
        # The slot visitor writes no markers here. Its markers are nodes in the tree, and the values
        # compiler walking them would claim indices for markup rather than for the template.
        def values_source(template, source, config)
          visitor = slot_visitors(template, source, mark: false).first

          return "{}" unless visitor

          ::Herb::Engine::DynamicsCompiler.new(source, config.merge(slot_visitor: visitor, **VALUES_ESCAPING)).src
        end

        # How a template is compiled here, for anything that needs the same slots this does.
        #
        # A version is a digest of the slots a template has, and those depend on every visitor that
        # ran before the slot visitor. A map built without them names versions no page carries, so
        # the page and the map would agree about nothing.
        def compile_for_dependencies(source, path)
          template = ::Struct.new(:identifier, :format).new(path, :html)
          visitor = slot_visitors(template, source, mark: false).first

          return nil unless visitor

          visitors = [
            *validation_visitors(ReActionView.config.validation_mode),
            *debug_visitors(template),
            *head_visitors(template),
            *ReActionView.config.transform_visitors,
            visitor
          ]

          erb_implementation.new(source, filename: translate_path_for_editor(path), project_path: ::ReActionView.config.project_path, visitors: visitors).src

          visitor
        end

        def values_format?(template)
          template.respond_to?(:format) && template.format == :slots
        end

        # The engine holds no opinion about validation, so asking for it is asking for the visitors.
        #
        # `:raise` stops the compile at the first finding. `:overlay` collects instead, and the
        # findings reach the browser through `Herb::Engine::Report::Middleware` rather than through
        # markup the engine writes into the page.
        def validation_visitors(mode)
          case mode
          when :raise then ::Herb::Engine::Validators.all(fatal: true).to_a
          when :overlay then ::Herb::Engine::Validators.all(fatal: false).to_a
          else []
          end
        end

        def debug_visitors(template)
          return [] unless ::ReActionView.config.debug_mode_enabled? && local_template?(template)

          [::Herb::Engine::DebugVisitor.new]
        end

        # What `content_for_head` used to do. The markup goes into `<head>`, so it is only ever
        # added to a template that has one.
        def head_visitors(template)
          markup = reactionview_dev_tools_markup(template)

          return [] if markup.nil? || markup.empty?

          [::Herb::Engine::ContentForVisitor.new(markup, tag_name: "head")]
        end

        # Slot markers go on last, so what they mark is the template as everything else left it.
        #
        # Unlike the debug visitor this is not development only, because the markers are what the
        # browser addresses a template's dynamic parts by and they ship with the page. Only HTML
        # gets them, since a marker in a text template would be output rather than structure.
        def slot_visitors(template, source, mark: true)
          return [] unless values_format?(template) || (template.respond_to?(:format) && template.format == :html)

          mode = ::ReActionView.config.slot_mode_for(source)

          return [] unless mode

          [::Herb::Engine::SlotVisitor.new(mode: mode, mark: mark)]
        end

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

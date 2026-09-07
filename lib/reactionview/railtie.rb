# frozen_string_literal: true

module ReActionView
  class Railtie < Rails::Railtie
    # If you don't want to precompile ReActionView's assets (eg. because you're using propshaft),
    # you can do this in an initializer:
    #
    # config.after_initialize do
    #   config.assets.precompile -= ReActionView::Railtie::PRECOMPILE_ASSETS
    # end
    #
    PRECOMPILE_ASSETS = %w[
      reactionview-dev-tools.esm.js
      reactionview-dev-tools.umd.js
    ].freeze

    initializer "reactionview.assets", after: :load_config_initializers do |app|
      if ReActionView.config.debug_mode_enabled? && app.config.respond_to?(:assets)
        gem_root = Gem::Specification.find_by_name("reactionview").gem_dir

        app.config.assets.paths << File.join(gem_root, "app", "assets", "javascripts")
        app.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end

    initializer "reactionview.asset_manifest_check" do |app|
      next unless ReActionView.config.development?

      require_relative "middleware/asset_manifest_check"

      app.middleware.use ReActionView::Middleware::AssetManifestCheck
    end

    initializer "reactionview.diagnostics" do |app|
      next unless ReActionView.config.debug_mode_enabled? || ReActionView.config.validation_mode == :overlay || ReActionView.config.slots

      require "herb/engine/runtime/middleware"

      app.middleware.use ::Herb::Engine::Runtime::Middleware
    end

    initializer "reactionview.instrumentation", after: :load_config_initializers do |_app|
      next unless ReActionView.config.instrumentation.enabled

      require_relative "instrumentation"

      ReActionView::Instrumentation.install!
    end

    initializer "reactionview.error_page", after: :load_config_initializers do |app|
      next unless ReActionView.config.development?

      require "herb/engine/runtime/error_page"

      app.middleware.use(
        ::Herb::Engine::Runtime::ErrorPage,
        dev_tools: -> { ReActionView::Railtie.dev_tools_module_path },
        dev_server_port: -> { ReActionView.config.dev_server_port }
      )
    end

    def self.dev_tools_module_path
      ActionController::Base.helpers.asset_path("reactionview-dev-tools.esm.js")
    end

    initializer "reactionview.slots" do |app|
      next unless ReActionView.config.slots

      Mime::Type.register ReActionView::Slots::MIME_TYPE, ReActionView::Slots::FORMAT unless Mime[ReActionView::Slots::FORMAT]

      ActiveSupport.on_load(:action_controller_base) do
        prepend ReActionView::Slots::Rendering

        app.config.paths["app/views"].existent.each do |path|
          prepend_view_path ReActionView::Slots::Resolver.new(path)
        end
      end
    end

    initializer "reactionview.slots.reloading" do |app|
      next unless ReActionView.config.slots

      views = app.config.paths["app/views"].existent

      next if views.empty?

      watcher = app.config.file_watcher.new([], views.index_with { %w[erb] }) do
        ReActionView::Slots.reset_dependencies!
      end

      app.reloaders << watcher
      app.reloader.to_run { watcher.execute_if_updated }
    end

    initializer "reactionview.slots.dev_server", after: :load_config_initializers do |app|
      next unless ReActionView.config.slots
      next unless ReActionView.config.development?
      next unless ReActionView.config.dev_server_enabled?

      begin
        require "herb/dev"
      rescue LoadError
        next
      end

      ::Herb::Dev.compiler = ReActionView::Slots::DevCompiler.new

      view_paths = app.config.paths["app/views"].existent

      app.server { Railtie.boot_dev_server(view_paths: view_paths) }
    end

    def self.boot_dev_server(view_paths: nil)
      embedded = ::Herb::Dev.boot(
        ReActionView.config.project_path,
        watch_paths: view_paths,
        logger: ->(message) { Rails.logger.info("[Herb Dev Server] #{message}") }
      )

      if embedded
        $stdout.puts "* Herb Dev Server: ws://localhost:#{embedded.server.port} (embedded)"
      else
        $stdout.puts "* Herb Dev Server: not started, see the log"
      end
    end

    initializer "reactionview.register_herb_handler" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :herb, ReActionView::Template::Handlers::Herb
      end
    end

    config.after_initialize do
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :erb, ReActionView::Template::Handlers::ERB if ReActionView.config.intercept_erb
      end
    end
  end
end

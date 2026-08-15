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

    # Findings used to be written into the page as markup the engine generated. They are collected
    # per request now and handed to the browser as one payload, which is what this scopes and
    # injects. Without it a template compiled with validators still records what it found, into a
    # session nothing ever drains.
    initializer "reactionview.diagnostics" do |app|
      next unless ReActionView.config.debug_mode_enabled? || ReActionView.config.validation_mode == :overlay

      require "herb/engine/report/middleware"

      app.middleware.use ::Herb::Engine::Report::Middleware
    end

    # A request asks for values by format, and ActionView refuses a format it has never heard of:
    # `LookupContext#formats=` raises for anything outside `Template::Types.symbols`, which is the
    # registered Mime types. So the type has to exist before a controller can be asked for one.
    #
    # The resolver goes in front of the ones Rails built, because it answers only for `:slots` and
    # an `:html` request has to fall through it untouched.
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

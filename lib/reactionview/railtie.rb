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

    initializer "reactionview.assets" do |app|
      if ReActionView.config.development? && app.config.respond_to?(:assets)
        gem_root = Gem::Specification.find_by_name("reactionview").gem_dir

        app.config.assets.paths << File.join(gem_root, "app", "assets", "javascripts")
        app.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end

    initializer "reactionview.register_herb_handler" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :herb, ReActionView::Template::Handlers::Herb
      end
    end

    initializer "reactionview.middleware" do |app|
      app.middleware.use ReActionView::Middleware::TimingOutput if ReActionView.config.show_render_times?
    end

    config.after_initialize do
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :erb, ReActionView::Template::Handlers::ERB if ReActionView.config.intercept_erb
      end
    end
  end
end

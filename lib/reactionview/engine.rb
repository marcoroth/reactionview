# frozen_string_literal: true

module ReActionView
  class Engine < Rails::Engine
    PRECOMPILE_ASSETS = %w[
      reactionview-dev-tools.esm.js
      reactionview-dev-tools.umd.js
    ].freeze

    initializer "reactionview.assets" do |app|
      # Sprockets precompilation config (for backward compatibility)
      if ReActionView.config.development? && app.config.respond_to?(:assets)
        if app.config.assets.respond_to?(:precompile)
          app.config.assets.precompile += PRECOMPILE_ASSETS
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

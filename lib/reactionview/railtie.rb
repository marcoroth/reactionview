# frozen_string_literal: true

module ReActionView
  class Railtie < Rails::Railtie
    initializer "reactionview.assets" do |app|
      if ReActionView.config.development? && app.config.respond_to?(:assets)
        gem_root = Gem::Specification.find_by_name("reactionview").gem_dir

        app.config.assets.paths << File.join(gem_root, "app", "assets", "javascripts")
      end
    end

    initializer "reactionview.register_herb_handler" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :herb, ReActionView::Template::Handlers::Herb
      end
    end

    config.after_initialize do
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :erb, ReActionView::Template::Handlers::Herb if ReActionView.config.intercept_erb
      end
    end
  end
end

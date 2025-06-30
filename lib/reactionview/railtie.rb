# frozen_string_literal: true

require "reactionview/template_handler"

module ReActionView
  class Railtie < Rails::Railtie
    initializer "reactionview.template_handler.initialization" do
      ReActionView::TemplateHandler.prepend!
    end

    initializer "reactionview.register_template_handler" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :herb, ReActionView::Template::Handlers::Herb.new
      end
    end
  end
end

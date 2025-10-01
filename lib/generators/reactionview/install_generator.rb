# frozen_string_literal: true

require "rails/generators/base"

module ReActionView
  module Generators
    class InstallGenerator < Rails::Generators::Base
      namespace "reactionview:install"
      desc "Install ReActionView in your Rails application"

      source_root File.expand_path("templates", __dir__)

      def create_initializer
        say "Creating ReActionView initializer...", :green

        create_file "config/initializers/reactionview.rb", <<~RUBY
          # frozen_string_literal: true

          ReActionView.configure do |config|
            # Intercept .html.erb templates and process them with `Herb::Engine` for enhanced features
            # config.intercept_erb = true

            # Enable debug mode in development (adds debug attributes to HTML)
            config.debug_mode = Rails.env.development? && !ENV["REACTIONVIEW_DISABLE_DEBUG_MODE"]

            # Add custom transform visitors to process templates before compilation
            # config.transform_visitors = [
            #   Herb::Visitor::new
            # ]
          end
        RUBY
      end

      def show_installation_complete
        say "\nReActionView has been successfully installed! 🎉", :green
        say "\nNext steps:", :blue
        say "  1. Review config/initializers/reactionview.rb"
        say "  2. Enable `config.intercept_erb = true` to process all `*.html.erb` templates using `Herb::Engine`."
        say "  3. Create `*.html.herb` templates for explicit Herb usage."

        say "\nLearn more:", :yellow
        say "  GitHub:  https://github.com/marcoroth/reactionview"
        say "  Website: https://reactionview.dev"

        say "\n✨ Thanks for riding the bleeding edge with Herb 🌿 and ReActionView! 🚀", :cyan
      end
    end
  end
end

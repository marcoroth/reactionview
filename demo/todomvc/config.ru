# frozen_string_literal: true

# TodoMVC as a Rails application, in one file.
#
# Everything that makes this work is ReActionView's, and none of it is written here: the `:slots`
# format, the resolver that answers for it, the handler that compiles values instead of markup, and
# the decision to render those without a layout. What is left is a controller with one action.
#
#     bundle exec rackup demo/todomvc/config.ru
#
# The browser half is `@herb-tools/runtime`, built from the Herb checkout this app already depends
# on and served from `/assets`.

require "action_controller/railtie"

require "reactionview"

require_relative "store"

module TodoMVC
  class Application < Rails::Application
    config.root = __dir__
    config.eager_load = false
    config.consider_all_requests_local = true
    config.secret_key_base = "todomvc-demo"
    config.hosts.clear
    config.logger = Logger.new(IO::NULL)

    routes.append do
      root to: "todos#index"
    end
  end
end

ReActionView.configure do |config|
  # `.html.erb` goes through Herb, and every template is marked so the browser can find its dynamic
  # parts again. `:client` also parks the branches a request did not take, and the row a collection
  # would have rendered had it any, so both can be built without asking again.
  config.intercept_erb = true
  config.debug_mode = false
  config.slots = :client
end

TodoMVC::Application.initialize!

class TodosController < ActionController::Base
  # Named rather than implied, because the convention resolves through `ApplicationController` and
  # this app has none. A values request never sees it: ReActionView renders those without a layout,
  # since a layout is chrome and where `content_for` lives.
  layout "application"

  STORE = TodoMVC::Store.new

  # One action, answering with markup or with values depending on what was asked for. Nothing here
  # decides which: the format does, and the format is a request parameter.
  def index
    STORE.apply(request.query_parameters)

    STORE.assigns(request.query_parameters).each { |name, value| instance_variable_set(:"@#{name}", value) }

    render :index
  end
end

# The stylesheet and the client, from `assets/` beside this file.
assets = Rack::Static.new(
  TodoMVC::Application,
  urls: ["/assets"],
  root: __dir__,
  header_rules: [[:all, { "cache-control" => "no-store" }]]
)

# The browser half, from wherever the Herb checkout this app depends on was built.
runtime = Rack::Static.new(
  assets,
  urls: { "/assets/herb-runtime.js" => "/herb-runtime.esm.js" },
  root: File.expand_path("javascript/packages/runtime/dist", Gem.loaded_specs["herb"].full_gem_path),
  header_rules: [[:all, { "cache-control" => "no-store" }]]
)

run runtime

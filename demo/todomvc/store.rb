# frozen_string_literal: true

require "securerandom"

module TodoMVC
  # The todos, and everything the template wants to know about them.
  #
  # In memory, so they reset when the server does, and behind a lock because a demo is still a
  # server. A real one would have a database here and nothing else would change.
  class Store
    FILTERS = ["all", "active", "completed"].freeze

    ACTIONS = {
      "add" => :add,
      "toggle" => :toggle,
      "edit" => :retitle,
      "destroy" => :destroy,
      "toggle-all" => :toggle_all,
      "clear" => :clear,
    }.freeze

    SEEDS = [
      { id: "seed-1", title: "Read what a slot is", done: true },
      { id: "seed-2", title: "Watch the values arrive", done: false },
      { id: "seed-3", title: "Add one of your own", done: false }
    ].freeze

    def initialize
      @todos = SEEDS.map(&:dup)
      @lock = Mutex.new
    end

    def apply(params)
      action = ACTIONS[params["do"]]

      @lock.synchronize { send(action, params) } if action
    end

    # Every value the template reads. Deciding them here rather than in the template is not only
    # tidiness: a conditional inside a tag has no markup to park, so its branches cannot be built by
    # the client, and a class decided in Ruby is a plain attribute slot like any other.
    def assigns(params)
      filter = FILTERS.include?(params["filter"]) ? params["filter"] : "all"

      { filter: filter, visible: decorate(visible(filter)), selected: selected(filter) }.merge(counts)
    end

    private

    def counts
      remaining = @todos.count { |todo| !todo[:done] }

      {
        remaining: remaining,
        noun: remaining == 1 ? "item" : "items",
        all_done: @todos.any? && remaining.zero?,
        main_class: @todos.empty? ? "main hidden" : "main",
        footer_class: @todos.empty? ? "footer hidden" : "footer",
        clear_class: @todos.any? { |todo| todo[:done] } ? "clear-completed" : "clear-completed hidden",
      }
    end

    def selected(filter)
      FILTERS.to_h { |name| [name, name == filter ? "selected" : ""] }
    end

    def decorate(todos)
      todos.map { |todo| todo.merge(css: todo[:done] ? "completed" : "") }
    end

    def visible(filter)
      case filter
      when "active" then @todos.reject { |todo| todo[:done] }
      when "completed" then @todos.select { |todo| todo[:done] }
      else @todos
      end
    end

    def add(params)
      title = params["title"].to_s.strip

      @todos << { id: "todo-#{SecureRandom.hex(4)}", title: title, done: false } unless title.empty?
    end

    def toggle(params)
      find(params) { |todo| todo[:done] = !todo[:done] }
    end

    def retitle(params)
      find(params) { |todo| todo[:title] = params["title"].to_s.strip }
    end

    def destroy(params)
      @todos.reject! { |todo| todo[:id] == params["id"] }
    end

    def toggle_all(_params)
      done = @todos.all? { |todo| todo[:done] }

      @todos.each { |todo| todo[:done] = !done }
    end

    def clear(_params)
      @todos.reject! { |todo| todo[:done] }
    end

    def find(params)
      todo = @todos.find { |candidate| candidate[:id] == params["id"] }

      yield todo if todo
    end
  end
end

# frozen_string_literal: true

module ReActionView
  # What a page did while it rendered, filed against the tags that did it.
  #
  # `Herb::Engine::InstrumentationVisitor` says which tag is rendering at any moment. It does not
  # say what is worth noticing while one is, because that is not the engine's business: an
  # application knows what it cares about, and Rails already announces most of it through
  # `ActiveSupport::Notifications`.
  #
  # These are the three worth having in every application, so they are here rather than in each one:
  # the queries a tag ran, what a render cost, and what a translation rendered. Each is a subscriber
  # that observes, plus a measurement that says how to read what was observed. Either half can be
  # turned off on its own.
  #
  #     ReActionView.configure do |config|
  #       config.instrumentation = true
  #       config.instrumentation.sql_queries = false
  #     end
  #
  module Instrumentation
    TRANSLATION_TAGS = [/\At\(/, /\Atranslate\(/].freeze #: Array[Regexp]
    IGNORED_QUERIES = ["SCHEMA", "TRANSACTION"].freeze #: Array[String]
    RENDER_EVENTS = %w[
      render_partial.action_view
      render_collection.action_view
      render_template.action_view
    ].freeze #: Array[String]

    def self.available?
      require "herb/engine/runtime/session"

      ::Herb::Engine::Runtime::Session.respond_to?(:measurement)
    rescue LoadError
      false
    end

    def self.install!(config = ReActionView.config)
      return unless config.instrumentation.enabled
      return unless available?
      return if installed?

      @installed = true

      install_sql_queries if config.instrumentation.measuring?(:sql_queries)
      install_render_times if config.instrumentation.measuring?(:render_times)
      install_translations if config.instrumentation.measuring?(:translations)

      config.transform_visitors += [visitor(config)]

      nil
    end

    def self.installed?
      @installed == true
    end

    def self.reset!
      @installed = false
    end

    def self.visitor(config = ReActionView.config)
      require "herb/engine/visitors/instrumentation_visitor"

      ::Herb::Engine::InstrumentationVisitor.new(capture_output: config.instrumentation.measuring?(:translations) ? TRANSLATION_TAGS : nil)
    end

    def self.install_sql_queries
      ::ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        next if payload[:cached]
        next if IGNORED_QUERIES.include?(payload[:name])

        session.observe(:queries, payload[:sql])
      end

      session.measurement(
        :queries,
        origin: "Herb Engine (Runtime)",
        code: "sql-queries",
        description: ->(queries) { "This ERB tag ran #{queries.size} SQL #{"query".pluralize(queries.size)} while the page rendered." }
      ) { |queries| "#{queries.size} SQL #{"query".pluralize(queries.size)}" }
    end

    def self.install_render_times
      RENDER_EVENTS.each do |event|
        ::ActiveSupport::Notifications.subscribe(event) do |notification|
          session.observe(:render, {
            duration: notification.duration.round(2),
            gc: notification.gc_time.round(2),
            allocations: notification.allocations,
            cached: notification.payload[:cache_hit] ? true : nil,
          }.compact)
        end
      end

      session.measurement(:render, origin: "Herb Engine (Runtime)", code: "render-time", description: method(:render_description)) do |renders|
        duration = renders.sum { |render| render[:duration] }.round(1)

        renders.size > 1 ? "#{duration} ms over #{renders.size} renders" : "#{duration} ms"
      end
    end

    def self.install_translations
      session.measurement(
        :output,
        origin: "Herb Engine (Runtime)",
        code: "rendered-output",
        kind: :value,
        per: :position,
        description: ->(values) { "This ERB tag rendered #{values.last.to_s.strip.inspect} when the page was last built." }
      ) { |values| values.last.to_s }
    end

    def self.render_description(renders)
      duration = renders.sum { |render| render[:duration] }
      gc = renders.sum { |render| render[:gc] }
      allocations = renders.sum { |render| render[:allocations] }
      cached = renders.count { |render| render[:cached] }

      parts = ["taking #{duration.round(1)} ms"]
      parts << "#{gc.round(1)} ms of it in GC" if gc.positive?
      parts << "allocating #{allocations.to_fs(:delimited)} objects" if allocations.positive?
      parts << "#{cached} served from cache" if cached.positive?

      if renders.size > 1
        "This tag rendered #{renders.size} times, #{parts.to_sentence}. Slowest was #{renders.map { |render| render[:duration] }.max.round(1)} ms."
      else
        "This tag rendered once, #{parts.to_sentence}."
      end
    end

    def self.session
      ::Herb::Engine::Runtime::Session
    end
  end
end

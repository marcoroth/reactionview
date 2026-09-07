# frozen_string_literal: true

require_relative "../test_helper"
require "reactionview/instrumentation"

class ReActionView::InstrumentationTest < Minitest::Spec
  def development_config
    config = ReActionView::Config.new

    def config.development?
      true
    end

    config
  end

  before do
    skip "this Herb has no measurement API" unless ReActionView::Instrumentation.available?
  end

  after do
    ReActionView::Instrumentation.reset!
    ::Herb::Engine::Runtime::Session.clear_measurements if ::Herb::Engine::Runtime::Session.respond_to?(:clear_measurements)
  end

  describe "when it runs" do
    test "measures while you are working on a page, and not otherwise" do
      config = ReActionView::Config.new

      def config.development?
        false
      end

      refute config.instrumentation.enabled
      assert development_config.instrumentation.enabled
    end

    test "measures anywhere it is asked for by name" do
      config = ReActionView::Config.new

      def config.development?
        false
      end

      config.instrumentation.enabled = true

      assert config.instrumentation.enabled
    end

    test "installs nothing when nothing is being measured" do
      config = ReActionView::Config.new
      config.instrumentation.enabled = false

      ReActionView::Instrumentation.install!(config)

      refute_predicate ReActionView::Instrumentation, :installed?
      assert_empty ::Herb::Engine::Runtime::Session.measurements
      assert_empty config.transform_visitors
    end

    test "installs once, however often it is asked" do
      config = development_config

      ReActionView::Instrumentation.install!(config)
      ReActionView::Instrumentation.install!(config)

      assert_equal 3, ::Herb::Engine::Runtime::Session.measurements.size
      assert_equal 1, config.transform_visitors.size
    end

    test "hands the compiler the visitor that makes a template say what it is rendering" do
      config = development_config

      ReActionView::Instrumentation.install!(config)

      assert_kind_of ::Herb::Engine::InstrumentationVisitor, config.transform_visitors.first
    end
  end

  describe "an engine that cannot be measured" do
    test "installs nothing rather than failing to boot" do
      ReActionView::Instrumentation.stub(:available?, false) do
        ReActionView::Instrumentation.install!(development_config)
      end

      refute_predicate ReActionView::Instrumentation, :installed?
    end
  end

  describe "how it is configured" do
    test "turns the whole thing off in one word" do
      config = development_config
      config.instrumentation.enabled = false

      refute config.instrumentation.enabled
      refute config.instrumentation.measuring?(:sql_queries)
    end

    test "remembers the built-ins that were turned off while it was off" do
      config = development_config
      config.instrumentation.render_times = false
      config.instrumentation.enabled = false
      config.instrumentation.enabled = true

      assert config.instrumentation.measuring?(:sql_queries)
      refute config.instrumentation.measuring?(:render_times)
    end
  end

  describe "which measurements it installs" do
    test "installs all three by default" do
      ReActionView::Instrumentation.install!(development_config)

      assert_equal %w[sql-queries render-time rendered-output], ::Herb::Engine::Runtime::Session.measurements.map(&:code)
    end

    test "leaves out the one that was turned off" do
      config = development_config
      config.instrumentation.sql_queries = false

      ReActionView::Instrumentation.install!(config)

      assert_equal %w[render-time rendered-output], ::Herb::Engine::Runtime::Session.measurements.map(&:code)
    end

    test "turns each of them off on its own" do
      config = development_config
      config.instrumentation.render_times = false
      config.instrumentation.translations = false

      ReActionView::Instrumentation.install!(config)

      assert_equal %w[sql-queries], ::Herb::Engine::Runtime::Session.measurements.map(&:code)
    end

    test "keeps them all off while nothing is being measured" do
      config = ReActionView::Config.new
      config.instrumentation.enabled = false
      config.instrumentation.sql_queries = true

      refute config.instrumentation.measuring?(:sql_queries)
    end

    test "comes with every key it expects, and refuses the ones it does not" do
      options = ReActionView::Config.new.instrumentation

      assert_equal ReActionView::Config::InstrumentationOptions::KEYS.sort, options.keys.sort

      error = assert_raises(ArgumentError) { options.sql_querys = false }

      assert_includes error.message, "unknown instrumentation option"
    end
  end

  describe "the visitor it hands to the compiler" do
    test "knows a translation tag by either name it is written under" do
      matchers = ReActionView::Instrumentation::TRANSLATION_TAGS

      assert(matchers.any? { |matcher| matcher.match?('t(".title")') })
      assert(matchers.any? { |matcher| matcher.match?('translate(".title")') })
      refute(matchers.any? { |matcher| matcher.match?("title") })
    end

    test "captures nothing once translations are turned off" do
      config = development_config
      config.instrumentation.translations = false

      source = "<%= t(\".title\") %>"
      compiled = ::Herb::Engine.new(source, filename: "a.html.erb", visitors: [ReActionView::Instrumentation.visitor(config)]).src

      refute_includes compiled, "Session.output"
    end

    test "captures a translation while they are on" do
      source = "<%= t(\".title\") %>"
      compiled = ::Herb::Engine.new(source, filename: "a.html.erb", visitors: [ReActionView::Instrumentation.visitor(development_config)]).src

      assert_includes compiled, "Session.output"
    end
  end
end

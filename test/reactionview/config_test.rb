# frozen_string_literal: true

require_relative "../test_helper"

require "active_support/testing/deprecation"

class ReActionView::ConfigTest < Minitest::Spec
  include ActiveSupport::Testing::Deprecation

  test "defaults to :raise in test environment" do
    config = ReActionView::Config.new

    def config.test?
      true
    end

    assert_equal :raise, config.validation_mode
  end

  test "defaults to :overlay in non-test environments" do
    config = ReActionView::Config.new

    def config.test?
      false
    end

    assert_equal :overlay, config.validation_mode
  end

  test "explicit :overlay overrides test environment default" do
    config = ReActionView::Config.new

    def config.test?
      true
    end

    config.validation_mode = :overlay

    assert_equal :overlay, config.validation_mode
  end

  test "explicit :none disables validation" do
    config = ReActionView::Config.new

    def config.test?
      true
    end

    config.validation_mode = :none

    assert_equal :none, config.validation_mode
  end

  test "explicit :raise overrides non-test environment default" do
    config = ReActionView::Config.new

    def config.test?
      false
    end

    config.validation_mode = :raise

    assert_equal :raise, config.validation_mode
  end

  test "the dev server is on by default" do
    assert_predicate ReActionView::Config.new, :dev_server_enabled?
  end

  test "the dev server can be switched off" do
    config = ReActionView::Config.new
    config.dev_server = false

    refute_predicate config, :dev_server_enabled?
  end

  test "project_path defaults to Rails.root" do
    config = ReActionView::Config.new

    Rails.stub(:root, Pathname.new("/app")) do
      assert_equal "/app", config.project_path
    end
  end

  test "project_path returns the configured value" do
    config = ReActionView::Config.new
    config.project_path = "/Users/you/myapp"

    Rails.stub(:root, Pathname.new("/app")) do
      assert_equal "/Users/you/myapp", config.project_path
    end
  end

  test "project_path falls back to Rails.root when reset to nil" do
    config = ReActionView::Config.new
    config.project_path = "/Users/you/myapp"
    config.project_path = nil

    Rails.stub(:root, Pathname.new("/app")) do
      assert_equal "/app", config.project_path
    end
  end

  test "dev_server_port is nil outside of development" do
    config = ReActionView::Config.new

    def config.development?
      false
    end

    assert_nil config.dev_server_port
  end

  test "explicit dev_server_port is used without consulting Herb" do
    config = ReActionView::Config.new

    def config.development?
      raise "should not be called"
    end

    config.dev_server_port = 1234

    assert_equal 1234, config.dev_server_port
  end

  test "dev_server_port is detected from Herb in development" do
    config = ReActionView::Config.new

    def config.development?
      true
    end

    with_detected_dev_server_port(8592) do |calls|
      assert_equal 8592, config.dev_server_port
      assert_equal [Rails.root.to_s], calls
    end
  end

  private

  def with_detected_dev_server_port(port)
    require "herb/dev/server_entry"

    calls = []
    entry = ::Herb::Dev::ServerEntry
    original = entry.method(:port_for)

    silence_warnings do
      entry.define_singleton_method(:port_for) do |project_path = nil|
        calls << project_path

        port
      end
    end

    yield calls
  ensure
    silence_warnings { entry.define_singleton_method(:port_for, original) }
  end

  def silence_warnings
    original = $VERBOSE
    $VERBOSE = nil

    yield
  ensure
    $VERBOSE = original
  end

  test "the engine visitors start as an empty stack" do
    visitors = ReActionView::Config.new.engine.visitors

    assert_kind_of Herb::Visitor::Stack, visitors
    assert_empty visitors
  end

  test "transform_visitors= fills the engine stack and says it is deprecated" do
    config = ReActionView::Config.new
    visitor = Herb::Visitor.new

    assert_deprecated(/config\.engine\.visitors\.use/, ReActionView.deprecator) do
      config.transform_visitors = [visitor]
    end

    assert_equal [visitor], config.engine.visitors.to_a
  end

  test "transform_visitors reads the engine stack and says it is deprecated" do
    config = ReActionView::Config.new
    visitor = Herb::Visitor.new

    config.engine.visitors.use(visitor)

    read = assert_deprecated(/config\.engine\.visitors/, ReActionView.deprecator) do
      config.transform_visitors
    end

    assert_same config.engine.visitors, read
  end

  test "the engine parser options start empty" do
    assert_empty ReActionView::Config.new.engine.parser_options
  end

  test "engine parser options take symbol keys whichever way they were written" do
    config = ReActionView::Config.new
    config.engine.parser_options = { "strict_locals" => true, prism_program: false }

    assert_equal({ strict_locals: true, prism_program: false }, config.engine.parser_options)
  end

  test "engine parser options refuse anything but a Hash" do
    error = assert_raises(ArgumentError) { ReActionView::Config.new.engine.parser_options = [:strict_locals] }

    assert_match(/must be a Hash/, error.message)
  end
end

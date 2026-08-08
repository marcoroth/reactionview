# frozen_string_literal: true

require_relative "../test_helper"

class ReActionView::ConfigTest < Minitest::Spec
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
    calls = []
    original = ::Herb.method(:dev_server_port)

    silence_warnings do
      ::Herb.define_singleton_method(:dev_server_port) do |project_path = nil|
        calls << project_path

        port
      end
    end

    yield calls
  ensure
    silence_warnings { ::Herb.define_singleton_method(:dev_server_port, original) }
  end

  def silence_warnings
    original = $VERBOSE
    $VERBOSE = nil

    yield
  ensure
    $VERBOSE = original
  end
end

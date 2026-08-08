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
end

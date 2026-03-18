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
end

# frozen_string_literal: true

require_relative "test_helper"

class TestReActionView < Minitest::Spec
  test "has version number" do
    refute_nil ::ReActionView::VERSION
  end
end

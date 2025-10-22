# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rails"
require "action_view"
require "reactionview"

require "pathname"

require "maxitest/autorun"
require "minitest/spec"

require_relative "snapshot_utils"

Minitest::Spec::DSL.send(:alias_method, :test, :it)
Minitest::Spec::DSL.send(:alias_method, :xtest, :xit)

class Minitest::Spec
  include SnapshotUtils
end

# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "herb", "0.11.2"
# TODO: Move back to a `ruby/prism` release tag once a Prism release includes ruby/prism#4334. This is `v2.1.0` plus that pull request.
gem "prism", github: "marcoroth/prism", ref: "4691667e2215831ae855add71d9925c0b871a709"

gem "actionview", "~> 8.1"
gem "appraisal"
# TODO: Move back to `~> 7.0` once `minitest` 6 allows Prism 2, it currently requires `prism ~> 1.5`.
gem "maxitest", "~> 6.0"
gem "minitest-difftastic"
gem "minitest-mock"
gem "railties", "~> 8.1"
gem "rake", "~> 13.0"
gem "readline", "~> 0.0.4"
gem "tsort", "~> 0.2.0"

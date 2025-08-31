# frozen_string_literal: true

require_relative "lib/reactionview/version"

Gem::Specification.new do |spec|
  spec.name = "reactionview"
  spec.version = ReActionView::VERSION
  spec.authors = ["Marco Roth"]
  spec.email = ["marco.roth@intergga.ch"]

  spec.summary = "Reactive ActionView"
  spec.description = spec.summary
  spec.homepage = "https://github.com/marcoroth/reactionview"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/marcoroth/reactionview/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "reactionview.gemspec",
    "LICENSE.txt",
    "Rakefile",
    "README.md",
    "app/**/*.rb",
    "app/assets/javascripts/**/*.{js,js.map}",
    "exe/*",
    "sig/**/*.rbs",
    "lib/**/*.{rb,tt,rake}"
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actionview", ">= 7.0"
  spec.add_dependency "herb", "~> 0.6.1"
  spec.add_dependency "nokogiri"
  spec.add_dependency "prism"
end

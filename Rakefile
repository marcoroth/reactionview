# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Run RuboCop from its own bundle, see gemfiles/rubocop.gemfile"
task :rubocop do
  Bundler.with_unbundled_env do
    sh({ "BUNDLE_GEMFILE" => File.expand_path("gemfiles/rubocop.gemfile", __dir__) }, "bundle exec rubocop")
  end
end

task default: %i[test rubocop]

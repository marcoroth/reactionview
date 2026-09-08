# frozen_string_literal: true

require_relative "../test_helper"

require "tmpdir"
require "rails/generators"
require "rails/generators/test_case"
require "generators/reactionview/install_generator"

class ReActionView::InstallGeneratorTest < Rails::Generators::TestCase
  tests ReActionView::Generators::InstallGenerator
  destination File.join(Dir.tmpdir, "reactionview-install-generator")

  setup do
    prepare_destination
  end

  test "creates the initializer" do
    run_generator

    assert_file "config/initializers/reactionview.rb", /ReActionView.configure/
  end

  test "leaves the importmap alone and imports the client for an importmap application" do
    Dir.chdir(destination_root) do
      FileUtils.mkdir_p("config")
      FileUtils.mkdir_p("app/javascript")
      File.write("config/importmap.rb", %(pin "application"\n))
      File.write("app/javascript/application.js", %(import "@hotwired/turbo-rails"\n))

      run_generator
    end

    assert_file "config/importmap.rb", %(pin "application"\n)
    assert_file "app/javascript/application.js", /import "reactionview"/
  end

  test "leaves a bundler application to its package manager" do
    Dir.chdir(destination_root) do
      FileUtils.mkdir_p("app/javascript")
      File.write("package.json", "{}\n")
      File.write("app/javascript/application.js", "")

      output = run_generator

      assert_match(/yarn add reactionview/, output)
    end

    assert_no_file "config/importmap.rb"
    assert_file "app/javascript/application.js", /import "reactionview"/
  end

  test "names the package manager the application already uses" do
    Dir.chdir(destination_root) do
      FileUtils.mkdir_p("app/javascript")
      File.write("package.json", "{}\n")
      File.write("package-lock.json", "{}\n")
      File.write("app/javascript/application.js", "")

      assert_match(/npm install reactionview/, run_generator)
    end
  end
end

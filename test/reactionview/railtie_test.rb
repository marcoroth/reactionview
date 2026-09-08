# frozen_string_literal: true

require_relative "../test_helper"

class ReActionView::RailtieTest < Minitest::Spec
  class FakeAssets
    attr_accessor :paths, :precompile

    def initialize
      @paths = []
      @precompile = []
    end
  end

  class FakeImportmap
    attr_accessor :paths, :cache_sweepers

    def initialize
      @paths = []
      @cache_sweepers = []
    end
  end

  class FakeConfig
    attr_reader :assets

    def initialize(importmap: true)
      @assets = FakeAssets.new

      return unless importmap

      map = FakeImportmap.new

      define_singleton_method(:importmap) { map }
    end
  end

  class FakeApp
    attr_reader :config

    def initialize(importmap: true)
      @config = FakeConfig.new(importmap: importmap)
    end
  end

  before do
    @previous_debug_mode = ReActionView.config.debug_mode
    @app = FakeApp.new
  end

  after do
    ReActionView.config.debug_mode = @previous_debug_mode
  end

  def assets_initializer
    ReActionView::Railtie.initializers.find { |initializer| initializer.name == "reactionview.assets" }
  end

  def run_assets_initializer(env)
    Rails.stub(:env, ActiveSupport::StringInquirer.new(env)) do
      assets_initializer.run(@app)
    end
  end

  def importmap_initializer
    ReActionView::Railtie.initializers.find { |initializer| initializer.name == "reactionview.importmap" }
  end

  def gem_javascripts_path
    File.join(Gem::Specification.find_by_name("reactionview").gem_dir, "app", "assets", "javascripts")
  end

  def gem_importmap_path
    File.join(Gem::Specification.find_by_name("reactionview").gem_dir, "lib", "reactionview", "importmap.rb")
  end

  test "runs after config initializers so it can see the configured debug_mode" do
    assert_equal :load_config_initializers, assets_initializer.after
  end

  test "installs assets outside development when debug mode is disabled" do
    ReActionView.config.debug_mode = false

    run_assets_initializer("production")

    assert_includes @app.config.assets.paths, gem_javascripts_path
    assert_equal ReActionView::Railtie::PRECOMPILE_ASSETS, @app.config.assets.precompile
  end

  test "installs assets in development when debug mode is left unset" do
    ReActionView.config.debug_mode = nil

    run_assets_initializer("development")

    assert_includes @app.config.assets.paths, gem_javascripts_path
  end

  test "draws its own importmap before the application's" do
    assert_equal "importmap", importmap_initializer.before

    importmap_initializer.run(@app)

    assert_includes @app.config.importmap.paths, gem_importmap_path
    assert_includes @app.config.importmap.cache_sweepers, gem_javascripts_path
  end

  test "stays out of the way without importmap-rails" do
    app = FakeApp.new(importmap: false)

    importmap_initializer.run(app)

    refute_respond_to app.config, :importmap
  end

  test "pins the client runtime as a preloaded module" do
    pins = []
    drawer = Object.new
    drawer.define_singleton_method(:pin) { |name, **options| pins << [name, options] }
    drawer.instance_eval(File.read(gem_importmap_path), gem_importmap_path)

    assert_equal [["reactionview", { to: "reactionview.esm.js", preload: true }]], pins
  end

  test "precompiles the client runtime alongside the dev tools" do
    assert_includes ReActionView::Railtie::PRECOMPILE_ASSETS, "reactionview.esm.js"
    assert_includes ReActionView::Railtie::PRECOMPILE_ASSETS, "reactionview-dev-tools.umd.js"
  end
end

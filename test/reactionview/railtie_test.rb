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

  class FakeConfig
    attr_reader :assets

    def initialize
      @assets = FakeAssets.new
    end
  end

  class FakeApp
    attr_reader :config

    def initialize
      @config = FakeConfig.new
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

  def gem_javascripts_path
    File.join(Gem::Specification.find_by_name("reactionview").gem_dir, "app", "assets", "javascripts")
  end

  test "runs after config initializers so it can see the configured debug_mode" do
    assert_equal :load_config_initializers, assets_initializer.after
  end

  test "installs assets outside development when debug mode is enabled" do
    ReActionView.config.debug_mode = true

    run_assets_initializer("production")

    assert_includes @app.config.assets.paths, gem_javascripts_path
    assert_equal ReActionView::Railtie::PRECOMPILE_ASSETS, @app.config.assets.precompile
  end

  test "does not install assets when debug mode is disabled" do
    ReActionView.config.debug_mode = false

    run_assets_initializer("production")

    assert_empty @app.config.assets.paths
    assert_empty @app.config.assets.precompile
  end

  test "installs assets in development when debug mode is left unset" do
    ReActionView.config.debug_mode = nil

    run_assets_initializer("development")

    assert_includes @app.config.assets.paths, gem_javascripts_path
  end

  test "does not install assets outside development when debug mode is left unset" do
    ReActionView.config.debug_mode = nil

    run_assets_initializer("production")

    assert_empty @app.config.assets.paths
  end
end

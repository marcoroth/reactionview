# frozen_string_literal: true

require_relative "../../test_helper"

require "reactionview/middleware/asset_manifest_check"

require "json"
require "tmpdir"

unless defined?(Propshaft::MissingAssetError)
  module Propshaft
    class MissingAssetError < StandardError; end
  end
end

class ReActionView::Middleware::AssetManifestCheckTest < Minitest::Spec
  class TestLogger
    attr_reader :messages

    def initialize
      @messages = []
    end

    def warn(message)
      @messages << message
    end
  end

  StaticResolver = Struct.new(:manifest_path)
  DynamicResolver = Struct.new(:load_path)
  AssetsConfig = Struct.new(:manifest_path, keyword_init: true)
  Assets = Struct.new(:config, :resolver, keyword_init: true)

  around do |test|
    Dir.mktmpdir do |dir|
      @dir = dir
      test.call
    end
  end

  def manifest_path
    File.join(@dir, ".manifest.json")
  end

  def write_manifest(logical_paths)
    entries = logical_paths.to_h { |path| [path, { "digested_path" => path, "integrity" => nil }] }

    File.write(manifest_path, JSON.generate(entries))
  end

  def build_assets(resolver: StaticResolver.new(manifest_path))
    Assets.new(config: AssetsConfig.new(manifest_path: manifest_path), resolver: resolver)
  end

  def missing_asset_error(asset = "reactionview-dev-tools.umd.js")
    Propshaft::MissingAssetError.new("The asset '#{asset}' was not found in the load path.")
  end

  def wrapped(error)
    raise error
  rescue StandardError
    begin
      raise ActionView::Template::Error, "template blew up"
    rescue ActionView::Template::Error => wrapper
      wrapper
    end
  end

  def build_middleware(assets: build_assets, logger: TestLogger.new, app: ->(_env) { [200, {}, ["ok"]] })
    ReActionView::Middleware::AssetManifestCheck.new(app, assets: assets, logger: logger)
  end

  describe "turning the Propshaft error into an explanation" do
    test "replaces the error when the manifest is missing the dev tools assets" do
      write_manifest(["application.js"])
      middleware = build_middleware(app: ->(_env) { raise missing_asset_error })

      error = assert_raises(ReActionView::StaleAssetManifestError) { middleware.call({}) }

      assert_includes error.message, "reactionview-dev-tools.umd.js"
      assert_includes error.message, "reactionview-dev-tools.esm.js"
      assert_includes error.message, manifest_path
      assert_includes error.message, "bin/rails assets:clobber"
    end

    test "keeps the original error available as the cause" do
      write_manifest(["application.js"])
      original = missing_asset_error
      middleware = build_middleware(app: ->(_env) { raise original })

      error = assert_raises(ReActionView::StaleAssetManifestError) { middleware.call({}) }

      assert_same original, error.cause
    end

    test "finds the Propshaft error when ActionView wrapped it" do
      write_manifest(["application.js"])
      wrapper = wrapped(missing_asset_error)
      middleware = build_middleware(app: ->(_env) { raise wrapper })

      assert_raises(ReActionView::StaleAssetManifestError) { middleware.call({}) }
    end

    test "leaves the error alone when the missing asset is not ours" do
      write_manifest(["application.js"])
      middleware = build_middleware(app: ->(_env) { raise missing_asset_error("some-other-asset.js") })

      assert_raises(Propshaft::MissingAssetError) { middleware.call({}) }
    end

    test "leaves the error alone when no manifest explains it" do
      middleware = build_middleware(app: ->(_env) { raise missing_asset_error })

      assert_raises(Propshaft::MissingAssetError) { middleware.call({}) }
    end

    test "leaves the error alone when the manifest does contain the dev tools assets" do
      write_manifest(["application.js"] + ReActionView::Railtie::PRECOMPILE_ASSETS)
      middleware = build_middleware(app: ->(_env) { raise missing_asset_error })

      assert_raises(Propshaft::MissingAssetError) { middleware.call({}) }
    end

    test "leaves unrelated errors alone" do
      write_manifest(["application.js"])
      middleware = build_middleware(app: ->(_env) { raise ArgumentError, "boom" })

      assert_raises(ArgumentError) { middleware.call({}) }
    end
  end

  describe "warning before the manifest takes effect" do
    test "warns when a stale manifest is not in use yet" do
      write_manifest(["application.js"])
      logger = TestLogger.new

      build_middleware(assets: build_assets(resolver: DynamicResolver.new([])), logger: logger).call({})

      assert_equal 1, logger.messages.size
      assert_includes logger.messages.first, "booted before public/assets/.manifest.json existed"
      assert_includes logger.messages.first, manifest_path
      assert_includes logger.messages.first, "bin/rails assets:clobber"
    end

    test "stays quiet when the manifest is already in use, since rendering raises instead" do
      write_manifest(["application.js"])
      logger = TestLogger.new

      build_middleware(assets: build_assets(resolver: StaticResolver.new(manifest_path)), logger: logger).call({})

      assert_empty logger.messages
    end

    test "stays quiet when the manifest contains the dev tools assets" do
      write_manifest(["application.js"] + ReActionView::Railtie::PRECOMPILE_ASSETS)
      logger = TestLogger.new

      build_middleware(assets: build_assets(resolver: DynamicResolver.new([])), logger: logger).call({})

      assert_empty logger.messages
    end

    test "stays quiet when no manifest exists" do
      logger = TestLogger.new

      build_middleware(assets: build_assets(resolver: DynamicResolver.new([])), logger: logger).call({})

      assert_empty logger.messages
    end

    test "stays quiet when the asset pipeline has no manifest path" do
      logger = TestLogger.new
      sprockets_like_assets = Struct.new(:config).new({})

      build_middleware(assets: sprockets_like_assets, logger: logger).call({})

      assert_empty logger.messages
    end

    test "stays quiet when there is no asset pipeline" do
      logger = TestLogger.new

      build_middleware(assets: nil, logger: logger).call({})

      assert_empty logger.messages
    end

    test "warns only once while the manifest is unchanged" do
      write_manifest(["application.js"])
      logger = TestLogger.new
      middleware = build_middleware(assets: build_assets(resolver: DynamicResolver.new([])), logger: logger)

      3.times { middleware.call({}) }

      assert_equal 1, logger.messages.size
    end

    test "warns again after the manifest changes" do
      write_manifest(["application.js"])
      logger = TestLogger.new
      middleware = build_middleware(assets: build_assets(resolver: DynamicResolver.new([])), logger: logger)

      middleware.call({})

      File.utime(Time.now + 5, Time.now + 5, manifest_path)

      middleware.call({})

      assert_equal 2, logger.messages.size
    end
  end

  test "passes the request through to the app" do
    write_manifest(["application.js"])

    assert_equal [200, {}, ["ok"]], build_middleware.call({})
  end
end

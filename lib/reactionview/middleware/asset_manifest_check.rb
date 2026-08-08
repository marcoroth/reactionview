# frozen_string_literal: true

require_relative "../asset_manifest"
require_relative "../stale_asset_manifest_error"

module ReActionView
  module Middleware
    class AssetManifestCheck
      def initialize(app, assets: nil, logger: nil)
        @app = app
        @assets = assets
        @logger = logger
        @mutex = Mutex.new
        @checked_mtime = nil
      end

      def call(env)
        warn_about_upcoming_failure

        @app.call(env)
      rescue StandardError => e
        raise unless dev_tools_asset_missing?(e)

        manifest = self.manifest

        raise unless manifest.stale?

        raise StaleAssetManifestError.for(manifest)
      end

      private

      def assets
        @assets || (defined?(Rails) && Rails.application&.assets)
      end

      def logger
        @logger || (defined?(Rails) && Rails.logger)
      end

      def manifest
        AssetManifest.new(assets)
      end

      def warn_about_upcoming_failure
        manifest = self.manifest
        mtime = manifest.mtime

        return if mtime.nil?

        @mutex.synchronize do
          return if @checked_mtime == mtime

          @checked_mtime = mtime

          return if manifest.in_use? || !manifest.stale?

          log("[ReActionView] #{manifest.explanation}")
        end
      end

      def dev_tools_asset_missing?(error)
        error_class = missing_asset_error_class

        return false if error_class.nil?

        while error
          if error.is_a?(error_class) &&
             ReActionView::Railtie::PRECOMPILE_ASSETS.any? { |asset| error.message.include?(asset) }
            return true
          end

          error = error.cause
        end

        false
      end

      def missing_asset_error_class
        return unless defined?(::Propshaft::MissingAssetError)

        ::Propshaft::MissingAssetError
      end

      def log(message)
        if logger
          logger.warn(message)
        else
          warn(message)
        end
      end
    end
  end
end

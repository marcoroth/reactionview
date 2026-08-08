# frozen_string_literal: true

require "json"

module ReActionView
  class AssetManifest
    def initialize(assets)
      @assets = assets
    end

    def path
      config = @assets&.config

      return unless config.respond_to?(:manifest_path)

      config.manifest_path
    end

    def mtime
      return if path.nil?

      File.mtime(path)
    rescue SystemCallError
      nil
    end

    def exist?
      !mtime.nil?
    end

    def missing_assets
      precompiled = logical_paths

      return [] if precompiled.empty?

      ReActionView::Railtie::PRECOMPILE_ASSETS - precompiled
    end

    def stale?
      exist? && !missing_assets.empty?
    end

    def in_use?
      @assets.respond_to?(:resolver) && @assets.resolver.respond_to?(:manifest_path)
    end

    def explanation
      <<~MESSAGE
        ReActionView's dev tools assets are missing from your precompiled assets.
        #{status}

        To fix this, delete the precompiled assets:

            bin/rails assets:clobber

        That is safe in development. Without public/assets/, Propshaft serves each asset straight from
        the directory it lives in, including ReActionView's.

            Missing:  #{missing_assets.join(", ")}
            Manifest: #{path}

        public/assets/ was most likely left behind by `RAILS_ENV=production bin/rails assets:precompile`,
        and a production precompile doesn't include ReActionView's dev tools.
      MESSAGE
    end

    private

    def status
      if in_use?
        "Because public/assets/.manifest.json exists, Propshaft serves every asset from public/assets/\n" \
          "and doesn't look anywhere else, which is why the lookup failed."
      else
        "This server booted before public/assets/.manifest.json existed, so pages still render for now.\n" \
          "After the next restart Propshaft will serve assets from public/assets/ only, and rendering\n" \
          "will fail then."
      end
    end

    def logical_paths
      return [] if path.nil?

      JSON.parse(File.read(path)).keys
    rescue SystemCallError, JSON::ParserError
      []
    end
  end
end

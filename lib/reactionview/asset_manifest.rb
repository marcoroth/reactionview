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
        ReActionView's dev tools assets are missing from the precompiled asset manifest.
        #{status}

        To fix this, delete the precompiled assets:

            bin/rails assets:clobber

        That is safe in development. Without a manifest, Propshaft serves assets straight from the
        load path, where these files already are.

            Missing:  #{missing_assets.join(", ")}
            Manifest: #{path}

        The manifest was most likely left behind by `RAILS_ENV=production bin/rails assets:precompile`.
        A production precompile doesn't include ReActionView's dev tools, and Propshaft stops scanning
        the load path as soon as a manifest exists.
      MESSAGE
    end

    private

    def status
      if in_use?
        "Propshaft is resolving assets from that manifest instead of the load path, which is why the\n" \
          "lookup failed."
      else
        "This server booted before the manifest existed, so pages still render for now. Propshaft will\n" \
          "resolve assets from the manifest after the next restart, and rendering will fail then."
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

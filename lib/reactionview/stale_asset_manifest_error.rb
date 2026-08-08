# frozen_string_literal: true

module ReActionView
  class StaleAssetManifestError < StandardError
    def self.for(manifest)
      new(manifest.explanation)
    end
  end
end

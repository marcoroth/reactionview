# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "tempfile"

module ReActionView
  class Cache
    attr_reader :directory

    def initialize(directory)
      @directory = directory
      @mem = {}
    end

    def fetch(key)
      mem_hit = @mem[key]
      return mem_hit if mem_hit

      path = cache_path(key)
      return nil unless File.exist?(path)

      src = File.read(path)
      @mem[key] = src
      src
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end

    def store(key, compiled_src)
      FileUtils.mkdir_p(@directory) unless Dir.exist?(@directory)

      path = cache_path(key)

      tmp = Tempfile.new(["reactionview_cache_", ".rb"], @directory)
      begin
        tmp.write(compiled_src)
        tmp.close
        File.rename(tmp.path, path)
      rescue StandardError
        tmp.close!
      end

      @mem[key] = compiled_src
    end

    def key_for(source, properties = {})
      fingerprint = {
        herb_version: defined?(::Herb::VERSION) ? ::Herb::VERSION : "unknown",
        reactionview_version: ReActionView::VERSION,
        ruby_version: RUBY_VERSION,
        validation_mode: properties.fetch(:validation_mode, :raise).to_s,
        bufvar: properties[:bufvar] || "@output_buffer",
        freeze_template_literals: properties.fetch(:freeze_template_literals, true),
        escapefunc: properties.fetch(:escapefunc, ""),
      }

      data = source + "\0" + JSON.generate(fingerprint.sort.to_h)
      Digest::SHA256.hexdigest(data)
    end

    def clear!
      @mem.clear
      FileUtils.rm_rf(@directory)
    end

    def size
      return 0 unless Dir.exist?(@directory)

      Dir.glob(File.join(@directory, "*.rb")).length
    end

    private

    def cache_path(key)
      File.join(@directory, "#{key}.rb")
    end
  end
end

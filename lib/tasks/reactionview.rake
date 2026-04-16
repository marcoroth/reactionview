# frozen_string_literal: true

namespace :reactionview do
  desc "Precompile all HTML ERB and Herb templates to the ReActionView cache"
  task precompile: :environment do
    require "reactionview/template/handlers/herb/herb"

    cache = ReActionView.cache
    config = ReActionView.config

    herb_config = Herb.configuration
    files = herb_config.find_files(Rails.root.to_s)

    if files.empty?
      puts "No template files found."
      exit(0)
    end

    compiled = 0
    errors = 0
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    files.each do |file|
      source = File.read(file)

      properties = {
        filename: file,
        project_path: Rails.root.to_s,
        validation_mode: config.validation_mode,
        content_for_head: nil,
        visitors: config.transform_visitors,
      }

      cache_properties = {
        filename: file,
        validation_mode: config.validation_mode,
        bufvar: "@output_buffer",
        freeze_template_literals: !ActionView::Template.frozen_string_literal,
        escapefunc: "",
      }

      cache_key = cache.key_for(source, cache_properties)

      begin
        compiled_src = ReActionView::Template::Handlers::Herb::Herb.new(source, properties).src
        cache.store(cache_key, compiled_src)
        compiled += 1
      rescue StandardError => e
        errors += 1
        puts "  Error: #{file}: #{e.message.lines.first&.chomp}"
      end
    end

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

    puts "Precompiled #{compiled} templates in #{format("%.2f", elapsed)}s"
    puts "  Cache directory: #{cache.directory}"
    puts "  Cache entries: #{cache.size}"
    puts "  Errors: #{errors}" if errors > 0
  end

  namespace :cache do
    desc "Clear the ReActionView template compilation cache"
    task clear: :environment do
      cache = ReActionView.cache
      count = cache.size
      cache.clear!

      puts "Cleared #{count} cached entries"
      puts "  Directory: #{cache.directory}"
    end
  end
end

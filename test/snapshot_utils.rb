# frozen_string_literal: true

# This is a copy of the SnapshotUtils from Herb:
# https://github.com/marcoroth/herb/blob/638e09f894e4473b661ec6d345d84f5c4d17aa74/test/snapshot_utils.rb

require "fileutils"
require "readline"
require "digest"
require "json"

def ask?(prompt = "")
  Readline.readline("===> #{prompt}? (y/N) ", true).squeeze(" ").strip == "y"
end

module SnapshotUtils # rubocop:disable Metrics/ModuleLength
  def assert_compiled_snapshot(source, handler: ReActionView::Template::Handlers::ERB, virtual_path: "test", format: :html, locals: [], options: {}) # rubocop:disable Metrics/ParameterLists
    template = ActionView::Template.new(
      source,
      "test_template",
      handler,
      virtual_path: virtual_path,
      format: format,
      locals: locals
    )

    compiled_source = template.handler.call(template, source)

    snapshot_key = JSON.generate({
      source: source,
      handler: handler,
      virtual_path: virtual_path,
      options: options,
      locals: locals,
      format: format,
    })

    assert_snapshot_matches(compiled_source, snapshot_key, mode: "compiled")

    compiled_source
  end

  def assert_evaluated_snapshot(source, ivars: {}, options: {}, handler: ReActionView::Template::Handlers::ERB, virtual_path: "test", format: :html, locals: []) # rubocop:disable Metrics/ParameterLists,Layout/LineLength
    template = ActionView::Template.new(
      source,
      "test_template",
      handler,
      virtual_path: virtual_path,
      format: format,
      locals: locals
    )

    compiled_source = template.handler.call(template, source)

    lookup_context = ActionView::LookupContext.new([])
    view_context = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)

    ivars.each do |key, value|
      view_context.instance_variable_set(:"@#{key}", value)
    end

    result = view_context.instance_eval(compiled_source).to_s

    snapshot_key = JSON.generate({
      source: source,
      ivars: ivars,
      locals: locals,
      options: options,
      handler: handler,
      format: format,
    })

    assert_snapshot_matches(result, snapshot_key, mode: "evaluated")

    { compiled: compiled_source, result: result }
  end

  def snapshot_changed?(content, source, options = {})
    if snapshot_file(source, options).exist?
      previous_content = snapshot_file(source, options).read

      if previous_content == content
        puts "\n\nSnapshot for '#{class_name} #{name}' didn't change: \n#{snapshot_file(source, options)}\n"
        false
      else
        puts "\n\nSnapshot for '#{class_name} #{name}' changed:\n"

        puts Difftastic::Differ.new(color: :always).diff_strings(previous_content, content)
        puts "==============="
        true
      end
    else
      puts "\n\nSnapshot for '#{class_name} #{name}' doesn't exist at: \n#{snapshot_file(source, options)}\n"
      true
    end
  end

  def save_failures_to_snapshot(content, source, options = {})
    return unless snapshot_changed?(content, source, options)

    puts "\n==== [ Input for '#{class_name} #{name}' ] ====="
    puts source
    puts "\n\n"

    if !ENV["FORCE_UPDATE_SNAPSHOTS"].nil? ||
       ask?("Do you want to update (or create) the snapshot for '#{class_name} #{name}'?")

      puts "\nUpdating Snapshot for '#{class_name} #{name}' at: \n#{snapshot_file(source, options)}\n"

      FileUtils.mkdir_p(snapshot_file(source, options).dirname)
      snapshot_file(source, options).write(content)

      puts "\nSnapshot for '#{class_name} #{name}' written: \n#{snapshot_file(source, options)}\n"
    else
      puts "\nNot updating snapshot for '#{class_name} #{name}' at: \n#{snapshot_file(source, options)}.\n"
    end
  end

  def assert_snapshot_matches(actual, source, options = {}, mode: nil)
    snapshot_opts = options.dup
    snapshot_opts[:mode] = mode if mode

    assert snapshot_file(source, snapshot_opts).exist?,
           "Expected snapshot file to exist: \n#{snapshot_file(source, snapshot_opts).to_path}"

    assert_equal snapshot_file(source, snapshot_opts).read, actual
  rescue Minitest::Assertion => e
    save_failures_to_snapshot(actual, source, snapshot_opts) if ENV["UPDATE_SNAPSHOTS"] || ENV["FORCE_UPDATE_SNAPSHOTS"]

    raise unless snapshot_file(source, snapshot_opts).exist?

    if snapshot_file(source, snapshot_opts)&.read != actual
      puts

      divider = "=" * `tput cols`.strip.to_i

      flunk(<<~MESSAGE)
        \e[0m
        #{divider}
        #{Difftastic::Differ.new(color: :always).diff_strings(snapshot_file(source, snapshot_opts).read, actual)}
        \e[31m#{divider}

        Snapshots for "#{class_name} #{name}" didn't match.

        Run the test using UPDATE_SNAPSHOTS=true to update (or create) the snapshot file for "#{class_name} #{name}"

        UPDATE_SNAPSHOTS=true minitest #{e.location}

        #{divider}
        \e[0m
      MESSAGE
    end
  end

  def snapshot_file(source, options = {}) # rubocop:disable Metrics/MethodLength
    test_class_name = underscore(self.class.name)

    content_hash = Digest::MD5.hexdigest(source || "#{source.class}-#{source.inspect}")

    test_name = sanitize_name_for_filesystem(name)

    mode = options[:mode]
    mode_suffix = mode ? "_#{mode}" : ""

    opts_for_hash = options.except(:mode)

    if opts_for_hash && !opts_for_hash.empty?
      options_hash = Digest::MD5.hexdigest(opts_for_hash.inspect)
      expected_snapshot_filename = "#{test_name}#{mode_suffix}_#{content_hash}-#{options_hash}.txt"
    else
      expected_snapshot_filename = "#{test_name}#{mode_suffix}_#{content_hash}.txt"
    end

    base_path = Pathname.new("test/snapshots/") / test_class_name
    expected_snapshot_path = base_path / expected_snapshot_filename

    return expected_snapshot_path if expected_snapshot_path.exist?

    matching_md5_files = if opts_for_hash && !opts_for_hash.empty?
                           Dir[base_path / "*#{mode_suffix}_#{content_hash}-#{options_hash}.txt"]
                         else
                           Dir[base_path / "*#{mode_suffix}_#{content_hash}.txt"]
                         end

    if matching_md5_files.any? && matching_md5_files.length == 1
      old_file = Pathname.new(matching_md5_files.first)

      return expected_snapshot_path if old_file.rename(expected_snapshot_path).zero?

      return old_file
    end

    expected_snapshot_path
  end

  private

  def sanitize_name_for_filesystem(name)
    [
      # ntfs reserved characters
      # https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file
      ["<", "lt"],
      [">", "gt"],
      [":", ""],
      ["/", "_"],
      ["\\", ""],
      ["|", ""],
      ["?", ""],
      ["*", ""],

      [" ", "_"]
    ].inject(name) { |name, substitution| name.gsub(substitution[0], substitution[1]) }
  end

  def underscore(string)
    string.gsub("::", "/")
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr("-", "_")
          .tr(" ", "_")
          .downcase
  end
end

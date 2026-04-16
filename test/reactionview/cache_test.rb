# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class ReActionView::CacheTest < Minitest::Spec
  def setup
    @cache_dir = Dir.mktmpdir("reactionview_cache_test_")
    @cache = ReActionView::Cache.new(@cache_dir)
  end

  def teardown
    FileUtils.rm_rf(@cache_dir)
  end

  test "fetch returns nil on cache miss" do
    assert_nil @cache.fetch("nonexistent_key")
  end

  test "store and fetch round-trip" do
    @cache.store("abc123", "compiled_source_code")
    assert_equal "compiled_source_code", @cache.fetch("abc123")
  end

  test "fetch reads from disk on cold memory" do
    @cache.store("disk_key", "from_disk")

    # Create a new cache instance pointing at the same directory (empty in-memory cache)
    cold_cache = ReActionView::Cache.new(@cache_dir)
    assert_equal "from_disk", cold_cache.fetch("disk_key")
  end

  test "fetch caches in memory after disk read" do
    @cache.store("mem_key", "cached_value")

    cold_cache = ReActionView::Cache.new(@cache_dir)
    cold_cache.fetch("mem_key")

    # Remove the file — should still return from memory
    FileUtils.rm_rf(@cache_dir)
    assert_equal "cached_value", cold_cache.fetch("mem_key")
  end

  test "store writes file to cache directory" do
    @cache.store("file_key", "file_content")

    path = File.join(@cache_dir, "file_key.rb")
    assert File.exist?(path)
    assert_equal "file_content", File.read(path)
  end

  test "key_for produces consistent SHA256 keys" do
    key1 = @cache.key_for("hello", { filename: "test.erb" })
    key2 = @cache.key_for("hello", { filename: "test.erb" })
    assert_equal key1, key2
    assert_match(/\A[0-9a-f]{64}\z/, key1)
  end

  test "key_for produces different keys for different sources" do
    key1 = @cache.key_for("hello", { filename: "test.erb" })
    key2 = @cache.key_for("world", { filename: "test.erb" })
    refute_equal key1, key2
  end

  test "key_for produces different keys for different properties" do
    key1 = @cache.key_for("hello", { filename: "a.erb" })
    key2 = @cache.key_for("hello", { filename: "b.erb" })
    refute_equal key1, key2
  end

  test "key_for produces different keys for different validation_mode" do
    key1 = @cache.key_for("hello", { validation_mode: :raise })
    key2 = @cache.key_for("hello", { validation_mode: :none })
    refute_equal key1, key2
  end

  test "clear! removes all cached entries" do
    @cache.store("key1", "value1")
    @cache.store("key2", "value2")
    assert_equal 2, @cache.size

    @cache.clear!

    assert_equal 0, @cache.size
    assert_nil @cache.fetch("key1")
    assert_nil @cache.fetch("key2")
  end

  test "size returns 0 for empty cache" do
    assert_equal 0, @cache.size
  end

  test "size returns count of cached entries" do
    @cache.store("a", "1")
    @cache.store("b", "2")
    @cache.store("c", "3")
    assert_equal 3, @cache.size
  end

  test "size returns 0 when directory does not exist" do
    cache = ReActionView::Cache.new("/tmp/nonexistent_reactionview_cache_#{$$}")
    assert_equal 0, cache.size
  end

  test "store overwrites existing entry" do
    @cache.store("overwrite_key", "old_value")
    @cache.store("overwrite_key", "new_value")

    assert_equal "new_value", @cache.fetch("overwrite_key")
    assert_equal 1, @cache.size
  end
end

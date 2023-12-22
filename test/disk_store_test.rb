# frozen_string_literal: true

require_relative './test_helper'

require 'byebug'

class DiskStoreTest < Minitest::Test
  # based on CacheStoreBehavior in activesupport

  def setup
    @cache = Puma::Acme::DiskStore.new(Dir.mktmpdir)
  end

  def test_should_read_and_write_strings
    key = SecureRandom.uuid
    assert_equal true, @cache.write(key, "bar")
    assert_equal "bar", @cache.read(key)
  end

  def test_should_overwrite
    key = SecureRandom.uuid
    assert_equal true, @cache.write(key, "bar")
    assert_equal true, @cache.write(key, "baz")
    assert_equal "baz", @cache.read(key)
  end

  def test_fetch_without_cache_miss
    key = SecureRandom.uuid
    @cache.write(key, "bar")
    assert_not_called(@cache, :write) do
      assert_equal "bar", @cache.fetch(key) { "baz" }
    end
  end

  def test_fetch_with_cache_miss_passes_key_to_block
    cache_miss = false
    key = SecureRandom.alphanumeric(10)
    assert_equal 10, @cache.fetch(key) { |key| cache_miss = true; key.length }
    assert cache_miss

    cache_miss = false
    assert_equal 10, @cache.fetch(key) { |fetch_key| cache_miss = true; fetch_key.length }
    assert !cache_miss
  end

  def test_fetch_with_forced_cache_miss_without_block
    key = SecureRandom.uuid
    @cache.write(key, "bar")
    assert_raises(ArgumentError) do
      @cache.fetch(key, force: true)
    end

    assert_equal "bar", @cache.read(key)
  end

  def test_should_read_and_write_hash
    key = SecureRandom.uuid
    assert_equal true, @cache.write(key, a: "b")
    assert_equal({ a: "b" }, @cache.read(key))
  end

  def test_should_read_and_write_integer
    key = SecureRandom.uuid
    assert_equal true, @cache.write(key, 1)
    assert_equal 1, @cache.read(key)
  end

  def test_should_read_and_write_nil
    key = SecureRandom.uuid
    assert_equal true, @cache.write(key, nil)
    assert_nil @cache.read(key)
  end

  def test_should_read_and_write_false
    key = SecureRandom.uuid
    assert_equal true, @cache.write(key, false)
    assert_equal false, @cache.read(key)
  end

  def test_hash_as_cache_key
    key = SecureRandom.alphanumeric
    other_key = SecureRandom.alphanumeric
    @cache.write({ key => 1, other_key => 2 }, "bar")
    assert_equal "bar", @cache.read({ key => 1, other_key => 2 })
  end

  def test_keys_are_case_sensitive
    key = "case_sensitive_key"
    @cache.write(key, "bar")
    assert_nil @cache.read(key.upcase)
  end

  def test_delete_returns_false_if_not_exist
    key = SecureRandom.alphanumeric
    assert_same false, @cache.delete(key)
  end

  def test_original_store_objects_should_not_be_immutable
    bar = +"bar"
    key = SecureRandom.alphanumeric
    @cache.write(key, bar)
    bar.gsub!(/.*/, "baz")
  end
end

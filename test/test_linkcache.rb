require './lib/tki-linkcheck'
Bundler.require(:test)

require 'minitest/autorun'

class TestLinkCache < MiniTest::Unit::TestCase
  def setup
    $redis = MockRedis.new
  end


  def teardown
    load './lib/tki-linkcheck/redis.rb'
    $options.linkcache_time = 60
  end


  def test_adding_link_to_cache
    LinkCache.add 'http://a.com', nil
    assert LinkCache.checked? 'http://a.com'
  end


  def test_non_urls_ignored
    LinkCache.add 'abc', nil
    refute LinkCache.checked? 'abc'
  end


  def test_responses_saved
    LinkCache.add 'http://thing.com', :not_found
    assert_equal :not_found, LinkCache.get('http://thing.com')
  end


  def test_nil_responses_transported
    LinkCache.add 'http://thing.com', nil
    refute LinkCache.get('http://thing.com')
  end


  def test_cache_idempotent
    LinkCache.add 'http://thing.com', nil
    LinkCache.add 'http://thing.com', nil
    LinkCache.add 'http://thing.com', nil
    assert_equal 1, $redis.scard(LinkCache.send(:class_variable_get, :@@keys)[:checked])
  end


  def test_cache_is_flushable
    $options.linkcache_time = 0
    LinkCache.add 'http://thing.com', nil
    LinkCache.add 'http://thing.com/a', nil
    assert LinkCache.checked? 'http://thing.com'
    assert LinkCache.checked? 'http://thing.com/a'
    LinkCache.flush
    refute LinkCache.checked? 'http://thing.com'
    refute LinkCache.checked? 'http://thing.com/a'
  end


  def test_cache_is_not_flushable_if_recently_active
    $options.linkcache_time = 60
    LinkCache.add 'http://thing.com', nil
    assert LinkCache.checked? 'http://thing.com'
    LinkCache.flush
    assert LinkCache.checked? 'http://thing.com'
  end


  def test_forced_flush_ignores_recency
    $options.linkcache_time = 60
    LinkCache.add 'http://thing.com', nil
    LinkCache.force_flush
    refute LinkCache.checked? 'http://thing.com'
  end
end

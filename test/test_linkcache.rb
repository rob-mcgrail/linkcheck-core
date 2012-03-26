require './lib/tki-linkcheck'
Bundler.require(:test)

require 'minitest/autorun'

class TestLinkCache < MiniTest::Unit::TestCase
  def setup
    $redis = MockRedis.new
  end
  
  
  def teardown
    load './lib/tki-linkcheck/redis.rb'
  end

  
  def test_adding_link_to_cache
    LinkCache.add 'http://a.com'
    assert LinkCache.checked? 'http://a.com'
  end
  
  
  def test_non_urls_ignored
    LinkCache.add 'abc'
    refute LinkCache.checked? 'abc'
  end
  
  
  def test_cache_idempotent
    LinkCache.add 'http://thing.com'
    LinkCache.add 'http://thing.com'
    LinkCache.add 'http://thing.com'
    assert_equal 1, $redis.scard(LinkCache.send(:class_variable_get, :@@key))
  end
  
  
  def test_cache_is_flushable
    LinkCache.add 'http://thing.com'
    LinkCache.add 'http://thing.com/a'
    assert LinkCache.checked? 'http://thing.com'
    assert LinkCache.checked? 'http://thing.com/a'
    LinkCache.flush
    refute LinkCache.checked? 'http://thing.com'
    refute LinkCache.checked? 'http://thing.com/a'
  end
end

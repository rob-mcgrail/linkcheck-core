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
    assert LinkCache.get 'http://a.com'
  end


  def test_responses_saved
    LinkCache.add 'http://thing.com', :not_found
    assert_equal "not_found", LinkCache.get('http://thing.com')
  end


  def test_no_problem_responses_return_empty_string
    LinkCache.add 'http://thing.com', nil
    assert_equal "", LinkCache.get('http://thing.com')
  end


  def test_cache_idempotent
    LinkCache.add 'http://thing.com', nil
    LinkCache.add 'http://thing.com', nil
    LinkCache.add 'http://thing.com', nil
    assert_equal 1, $redis.keys("#{$options.global_prefix}:response:*").length
  end


  def test_forced_flush_deleted_cache_keys
    $options.linkcache_time = 60
    LinkCache.add 'http://thing.com', nil
    assert LinkCache.get 'http://thing.com'
    LinkCache.flush
    assert_nil LinkCache.get 'http://thing.com'
  end
end

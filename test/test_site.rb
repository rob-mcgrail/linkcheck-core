require './lib/tki-linkcheck'
Bundler.require(:test)

require 'minitest/autorun'

class TestSite < MiniTest::Unit::TestCase
  def setup
    $redis = MockRedis.new
    @site = Site.new 'http://example.com'
  end
  
  
  def teardown
    load './lib/tki-linkcheck/redis.rb'
  end


  def test_domain_set_and_gettable
    assert_equal 'http://example.com', @site.address
  end
  
  
  def test_add_broken_creates_broken_data_sets_and_members
    @site.add_broken('http://example.com/a', 'http://a.com', 'problem1')
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:pages"), 'http://example.com/a'
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:page:http://example.com/a"), 'http://a.com'
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:problems"), 'problem1'
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:problem:problem1"), 'http://a.com'
  end
  
  
  def test_problems_can_be_symbols
    @site.add_broken('http://example.com/a', 'http://a.com', :problem1)
    
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:problems"), 'problem1'
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:problem:problem1"), 'http://a.com'
  end
  
  
  def test_broken_count_increments
    @site.add_broken('http://example.com/a', 'http://a.com', :problem1)
    @site.add_broken('http://example.com/b', 'http://b.com', :problem1)
    assert_equal '2', $redis.get("#{$options.global_prefix}:#{@site.address}:count:broken")
  end
  
  
  def test_log_link_increments_checked_count
    @site.log_link 'http://a.com'
    @site.log_link 'http://b.com'
    assert_equal '2', $redis.get("#{$options.global_prefix}:#{@site.address}:count:checked")
  end
  
  
  def test_log_link_adds_checked_link_to_cache
    @site.log_link 'http://a.com'
    @site.log_link 'http://b.com'
    assert LinkCache.checked? 'http://a.com'
    assert LinkCache.checked? 'http://b.com'
  end
  
  
  def test_log_page_increments_page_count
    @site.log_page 'http://example.com/a'
    @site.log_page 'http://example.com/b'
    assert_equal '2', $redis.get("#{$options.global_prefix}:#{@site.address}:count:pages")
  end
  
  
  def test_counters_resetable
    @site.log_link 'http://a.com'
    @site.log_link 'http://b.com'   
    @site.add_broken('http://example.com/a', 'http://a.com', :problem1)
    @site.log_page 'http://example.com/a'
    assert_equal '1', $redis.get("#{$options.global_prefix}:#{@site.address}:count:pages")
    assert_equal '2', $redis.get("#{$options.global_prefix}:#{@site.address}:count:checked")
    assert_equal '1', $redis.get("#{$options.global_prefix}:#{@site.address}:count:broken")
    @site.reset_counters
    assert_equal '0', $redis.get("#{$options.global_prefix}:#{@site.address}:count:pages")
    assert_equal '0', $redis.get("#{$options.global_prefix}:#{@site.address}:count:checked")
    assert_equal '0', $redis.get("#{$options.global_prefix}:#{@site.address}:count:broken")    
  end
  
  
  def test_flush_issues_deletes_pages_and_problems
    @site.log_link 'http://a.com'
    @site.log_link 'http://b.com'   
    @site.add_broken('http://example.com/a', 'http://a.com', :problem1)
    @site.log_page 'http://example.com/a'
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:pages"), 'http://example.com/a'
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:page:http://example.com/a"), 'http://a.com'
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:problems"), 'problem1'
    assert_includes $redis.smembers("#{$options.global_prefix}:#{@site.address}:problem:problem1"), 'http://a.com'
    @site.flush_issues
    assert_empty $redis.smembers("#{$options.global_prefix}:#{@site.address}:pages")
    assert_empty $redis.smembers("#{$options.global_prefix}:#{@site.address}:page:http://example.com/a")
    assert_empty $redis.smembers("#{$options.global_prefix}:#{@site.address}:problems")
    assert_empty $redis.smembers("#{$options.global_prefix}:#{@site.address}:problem:problem1")
  end
end
















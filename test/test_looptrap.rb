require './lib/tki-linkcheck'
Bundler.require(:test)

require 'minitest/autorun'
require 'webmock/minitest'

class TestLoopTrap < MiniTest::Unit::TestCase
  def setup
    $redis = MockRedis.new
    stub_request(:get, "test.com").to_return(:status => 200, :body=>'<a href="/1">thing</a>', :headers => {"Content-Type" => 'text/html'})
    stub_request(:get, "test.com/1").to_return(:status => 200, :body=>'<a href="/2">thing</a>', :headers => {"Content-Type" => 'text/html'})
    stub_request(:get, "test.com/2").to_return(:status => 200, :body=>'<a href="/3">thing</a>', :headers => {"Content-Type" => 'text/html'})
    stub_request(:get, "test.com/3").to_return(:status => 200, :body=>'<a href="/2">thing</a>', :headers => {"Content-Type" => 'text/html'})
  end


  def teardown
    load './lib/tki-linkcheck/redis.rb'
  end


  def test_looptrap_triggers
    $options.crawl_limit = 2
    site = Sites.create :location => 'http://test.com'
    Crawler.new(site).crawl
    assert_equal 2, site.pages_checked_count
  end
end

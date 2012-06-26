#require './lib/tki-linkcheck'
#Bundler.require(:test)

#require 'minitest/autorun'
#require 'webmock/minitest'

#class TestCrawler < MiniTest::Unit::TestCase
#  def setup
#    require 'ostruct'
#    @page = OpenStruct.new
#    @page.url = URI('http://example.com/abc')
#    @page.doc = Nokogiri::HTML(File.new('./test/mocks/main.html'))
#    $redis = MockRedis.new
#    LinkCache.force_flush
#    @crawler = Crawler.new('http://example.com')
#  end


#  def teardown
#    load './lib/tki-linkcheck/redis.rb'
#  end

#  # Haven't decided how to test this yet...

#  # But will mainly just test check_links(@page)

#  #  def test_valid_anchor_returns_nil
#  #    assert_nil @crawler.check_links(@page)

#  #  end
#end

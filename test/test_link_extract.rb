require './lib/tki-linkcheck'
Bundler.require(:test)

require 'minitest/autorun'

class TestLinkExtract < MiniTest::Unit::TestCase
  def setup
    require 'ostruct'
    @page = OpenStruct.new
    @page.url = URI('http://example.com/')
    @page.doc = Nokogiri::HTML(File.new('./test/mocks/links.html'))
  end


  def test_returns_array
    a = LinkExtract << @page
    assert_kind_of Array, a
  end


  def test_returns_empty_array_if_no_link
    page = OpenStruct.new
    page.url = URI('http://example.com/site_section')
    page.doc = Nokogiri::HTML('<html><body></body></html>')
    assert_kind_of Array, LinkExtract << page
  end


  def test_links_extracted
    a = LinkExtract << @page
    assert_equal 10, a.length
  end


  def test_array_contains_no_duplicates
    a = LinkExtract << @page
    refute a.uniq! # returns nil if no duplicates removed
  end


  def test_extracted_links_are_absolute
    a = LinkExtract << @page
    assert_includes a, "http://example.com/relative_url/1"
    assert_includes a, "http://example.com/relative_url/2"
    assert_includes a, "http://example.com/same_site_domain/1"
    assert_includes a, "http://example.com/same_site_domain/2"
    assert_includes a, "http://example.com/abs_url/1"
    assert_includes a, "http://example.com/abs_url/2"
    assert_includes a, "http://example.com/#anchor"
    assert_includes a, "http://example.com/some_page#anchor"
  end


  def test_relative_link_appropriately_prefixed
    page = OpenStruct.new
    page.url = URI('http://example.com/site_section')
    page.doc = Nokogiri::HTML('<html><body><a href="relative_url"></a></body></html>')
    a = LinkExtract << page
    assert_includes a, "http://example.com/site_section/relative_url"
  end
end

require './lib/tki-linkcheck'
Bundler.require(:test)

require 'minitest/autorun'
require 'webmock/minitest'

class TestCheckable < MiniTest::Unit::TestCase
#  def setup
#    @links = []
#    @links << 'http://example.com/'
#    @links << 'http://example.com'
#    @links << 'http://example.com '
#    @links << 'http:   //example.com '
#    
#    stub_request(:any, "example.com").to_return(:status => 200)
#    stub_request(:any, "gone.com").to_return(:status => 404)
#  end


#  def test_string_extended_by_checkable
#    string = ''
#    string.extend Checkable
#    assert_equal true, string.methods.include?('broken?')
#    assert_equal true, string.methods.include?('clean')
#  end

#  
#  def test_url_cleaned
#    require 'uri'
#    @links.each do |uri|
#      uri.extend Checkable
#      uri.clean
#      assert_kind_of URI, URI.parse(uri)
#    end
#  end
#  
#  
#  def test_valid_response_returns_nil
#    uri = 'http://example.com'
#    uri.extend Checkable
#    assert_nil uri.broken?      
#  end
#  

#  def test_missing_response_returns_nil
#    uri = 'http://gone.com'
#    uri.extend Checkable
#    assert uri.broken?
#  end
end

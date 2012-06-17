require './lib/tki-linkcheck'
Bundler.require(:test)

require 'minitest/autorun'

class TestSite < MiniTest::Unit::TestCase
  def setup
    @site = Site.new 'example.com'
  end

  def test_domain_set_and_gettable
    assert_equal 'example.com', @site.address
  end
  
  
  def test_prefixes_correct
  

  end
end

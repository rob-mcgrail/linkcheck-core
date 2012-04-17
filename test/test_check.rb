require './lib/tki-linkcheck'
Bundler.require(:test)

require 'minitest/autorun'
require 'webmock/minitest'

class TestCheck < MiniTest::Unit::TestCase
  def setup
    require 'ostruct'
    @doc = OpenStruct.new
    @doc.url = 'http://example.com/'
    @doc.doc = Nokogiri::HTML(File.new('./test/mocks/anchors.html'))
    @check = Check.new
  end


  def test_valid_anchor_returns_nil
    assert_nil @check.validate(@doc, 'http://example.com/#divId')
    assert_nil @check.validate(@doc, 'http://example.com/#namedAnchor')
  end


  def test_slashes_dont_matter
    assert_nil @check.validate(@doc, 'http://example.com#divId')
    assert_nil @check.validate(@doc, 'http://example.com/#divId')
  end


  def test_invalid_anchor_returns_correct_object
    assert_equal :bad_anchor, @check.validate(@doc, 'http://example.com/#someClass')
    assert_equal :bad_anchor, @check.validate(@doc, 'http://example.com/#nothingAtAll')
  end


  def test_invalid_anchor_returns_correct_object
    assert_equal :bad_anchor, @check.validate(@doc, 'http://example.com/#someClass')
    assert_equal :bad_anchor, @check.validate(@doc, 'http://example.com/#nothingAtAll')
  end


  def test_http_response_codes_return_correct_objects
    stub_request(:get, "example.com/page").to_return(:status => 200)
    assert_nil @check.validate(@doc, 'http://example.com/page')

    stub_request(:get, "example.com/page").to_return(:status => 404)
    assert_equal :not_found, @check.validate(@doc, 'http://example.com/page')

    stub_request(:get, "example.com/page").to_return(:status => 403)
    assert_equal :forbidden, @check.validate(@doc, 'http://example.com/page')

    stub_request(:get, "example.com/page").to_return(:status => 301)
    assert_equal :moved_permanently, @check.validate(@doc, 'http://example.com/page')

    stub_request(:get, "example.com/page").to_return(:status => 302)
    assert_nil @check.validate(@doc, 'http://example.com/page')

    stub_request(:get, "example.com/page").to_return(:status => 303)
    assert_equal :see_other, @check.validate(@doc, 'http://example.com/page')

    stub_request(:get, "example.com/page").to_return(:status => 503)
    assert_equal :unavailable, @check.validate(@doc, 'http://example.com/page')

    stub_request(:get, "example.com/page").to_return(:status => 500)
    assert_equal :unknown, @check.validate(@doc, 'http://example.com/page')

    stub_request(:get, "example.com/page").to_return(:status => 401)
    assert_equal :unknown, @check.validate(@doc, 'http://example.com/page')
  end


  def test_invalid_uris_return_correct_symbol
    assert_equal :ignored_for_scheme, @check.validate(@doc, 'some/thing')
    assert_equal :ignored_for_uri_class, @check.validate(@doc, 'http:// example.com')
  end
end

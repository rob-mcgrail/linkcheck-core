REQUEST_EXCEPTIONS = [NoMethodError, Timeout::Error, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError, Errno::ETIMEDOUT, EOFError, URI::InvalidURIError, HTTParty::UnsupportedURIScheme]


class Check
  require 'uri'
  require 'net/http'
  require 'net/https'


  def initialize(page_, link_)
    @page = page_
    @link = link_
  end


  def validate
    if @link =~ /^#{Regexp.escape(@page.url.to_s.gsub(/\/$/,''))}\/?#[^!]/
      validate_relative_anchor
    else
      cache_response = LinkCache.get @link # "" for fine, sym for problem, nil for uncached
      if cache_response
        parse_cache cache_response
      else
        response = validate_link
        LinkCache.add @link, response
        sleep $options.check_delay
        response
      end
    end
  end


  private


  def parse_cache(response)
    if response == ""
      nil
    else
      response.to_sym
    end
  end


  def validate_relative_anchor
    @link.gsub!(/^.+#/, '')
    unless @page.doc.at_xpath("//a[@name='#{@link}']", "//*[@id='#{@link}']")
      :bad_anchor
    else
      nil
    end
  end


  def validate_link
    anchorless_uri = @link.gsub(/#[^!].+/, '')

    uri = Addressable::URI.normalized_encode(
      Addressable::URI.unencode(anchorless_uri)
    )

    return response(uri)
  end


  def response(uri)
    response_code = get_response_code(uri)
    case response_code
    when 200..299
      nil
    when 404
      puts uri
      puts response_code
      :not_found
    when 403
      :forbidden
    when 301
      ignore_local nil
    when 302
      ignore_local nil
    when 303
      ignore_local nil
    when 503
      :unavailable
    else
      puts uri
      puts response_code
      :unknown
    end
  end


  def ignore_local(sym)
    # Ignoring local redirect responses as noise
    if /(#{Regexp.escape(@page.url.host)})/.match(@link)
      nil
    else
      sym
    end
  end


  def get_response_code(uri)
    begin
      c = Curl::Easy.new(uri)
      c.perform
      code = c.response_code
    rescue *REQUEST_EXCEPTIONS
      retry_count = (retry_count || 0) + 1
      sleep ($options.check_delay * retry_count * 2)
      retry unless retry_count >= $options.retry_count
      code = 'failed'
    end
    code
  end
end

REQUEST_EXCEPTIONS = [Timeout::Error, Errno::ECONNRESET, SocketError, Errno::ETIMEDOUT, EOFError]

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
        puts "Hitting cache #{cache_response}"
        parse_cache cache_response
      else
        response = validate_link
        LinkCache.add @link, response
        sleep $options.check_delay
        puts "Sleep - #{$options.check_delay}"
        puts "Validating link #{response}"
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
    if @link.gsub(' ', '%20') =~ URI::regexp($options.valid_schemes)
      begin
        link = @link.gsub(' ', '%20')
        uri = URI.parse(URI.encode(link))
      rescue URI::InvalidURIError
        return :invalid
      end
      if $options.checked_classes.member? uri.class
        response(uri)
      else
        :ignored_for_uri_class
      end
    else
      :invalid
    end
  end


  def response(uri)
    response_code = get_response_code(uri)
    case response_code
    when '200'
      nil
    when '404'
      :not_found
    when '403'
      :forbidden
    when '301'
      ignore_local :moved_permanently
    when '302'
      ignore_local nil
    when '303'
      ignore_local nil
    when '503'
      :unavailable
    else
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
    if uri.class == URI::HTTPS
      https_request(uri)
    else
      http_request(uri)
    end
  end


  def http_request(uri)
    begin
      response = Net::HTTP.get_response(uri)
      code = response.code
    rescue *REQUEST_EXCEPTIONS
      retry_count = (retry_count || 0) + 1
      sleep ($options.check_delay * retry_count * 2)
      retry unless retry_count >= $options.retry_count
      code = 'failed'
    end
    code
  end


  def https_request(uri)
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      code = response.code
    rescue *REQUEST_EXCEPTIONS
      retry_count = (retry_count || 0) + 1
      sleep ($options.check_delay * retry_count * 2)
      retry unless retry_count >= $options.retry_count
      code = 'failed'
    end
    code
  end
end

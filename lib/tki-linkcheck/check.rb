class Check
  require 'uri'
  require 'net/http'
  require 'net/https'

  def validate(page, link)
    if link =~ /^#{Regexp.escape(page.url.to_s.gsub(/\/$/,''))}\/?#[^!]/
      validate_relative_anchor(page, link)
    else
      if LinkCache.checked? link
        LinkCache.get link
      else
        response = validate_link(link)
        LinkCache.add link, response
        response
      end
    end
  end


  private

  def validate_relative_anchor(page, link)
    link.gsub!(/^.+#/, '')
    unless page.doc.at_xpath("//a[@name='#{link}']", "//*[@id='#{link}']")
      :bad_anchor
    else
      nil
    end
  end


  def validate_link(link)
    if link.gsub(' ', '%20') =~ URI::regexp($options.valid_schemes)
      begin
        uri = URI.parse(link.gsub(' ', '%20'))
      rescue URI::InvalidURIError
        :invalid
      end
      if $options.checked_classes.member? uri.class
        if uri.class == URI::HTTPS
          code = https_request(uri)
        else
          code = http_request(uri)
        end
        case code
        when '200'
          nil
        when '404'
          :not_found
        when '403'
          :forbidden
        when '301'
          :moved_permanently
        when '302' # Should this be removed?
          nil
        when '303'
          :see_other
        when '503'
          :unavailable
        else
          :unknown
        end
      else
        :ignored_for_uri_class
      end
    else
      :ignored_for_scheme
    end
  end


  def http_request(uri)
    begin
      response = Net::HTTP.get_response(uri)
      code = response.code
    rescue Timeout::Error, Errno::ECONNRESET, SocketError, Errno::ETIMEDOUT
      retry_count = (retry_count || 0) + 1
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
    rescue Timeout::Error, Errno::ECONNRESET, SocketError, Errno::ETIMEDOUT
      retry_count = (retry_count || 0) + 1
      retry unless retry_count >= $options.retry_count
      code = 'failed'
    end
    code
  end
end

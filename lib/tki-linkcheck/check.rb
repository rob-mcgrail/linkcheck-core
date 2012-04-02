class Check
  require 'uri'
  require 'net/http'
  require 'net/https'


  def self.validate(page, link)
    if link =~ /^#{Regexp.escape(page.url.to_s.gsub(/\/$/,''))}\/?#[^!]/
      validate_relative_anchor(page, link)
    else
      validate_link(link)
    end
  end


  private

  def self.validate_relative_anchor(page, link)
    link.gsub!(/^.+#/, '')
    unless page.doc.at_xpath("//a[@name='#{link}']", "//*[@id='#{link}']")
      :bad_anchor
    else
      nil
    end
  end


  def self.validate_link(link)
    if link =~ URI::regexp($options.valid_schemes)
      begin
        uri = URI.parse(link)
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
        :ignored
      end
    else
      :ignored
    end
  end


  def self.http_request(uri)
    begin
      response = Net::HTTP.get_response(uri)
      code = response.code
    rescue Timeout::Error
      retry_count = (retry_count || 0) + 1
      retry unless retry_count >= 2
      code = 'failed'
    end
    code
  end


  def self.https_request(uri)
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      code = response.code
    rescue Timeout::Error
      retry_count = (retry_count || 0) + 1
      retry unless retry_count >= 2
      code = 'failed'
    end
    code
  end


end

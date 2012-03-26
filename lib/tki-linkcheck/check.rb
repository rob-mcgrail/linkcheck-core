class Check
  require 'uri'
  require 'net/http'
  
  def self.validate(page, link)
    if link =~ /^#{Regexp.escape(page.url.to_s)}#[^!]/
      validate_relative_anchor(page, link)
    else
      validate_link(link)
    end
  end
  
  
  def self.validate_relative_anchor(page, link)
    link.gsub!(/^.+#/, '')
    unless page.doc.at_xpath("//a[@name='#{link}']", "//*[@id='#{link}']")
        :bad_anchor
    else
      nil
    end
  end
  
  
  def self.validate_link(link)
    begin
      uri = URI.parse(link)
    rescue URI::InvalidURIError
      :invalid
    end
    if uri.class == URI::HTTP  
      puts uri.class
      response = Net::HTTP.get_response(uri)
      puts response.code
      case response.code
      when '404'
        :not_found
      when '403'
        :forbidden
      when '301'
        :moved_permanently
      when '302'
        :found
      when '303'
        :see_other
      when '503'
        :unavailable
      else
        nil
      end
    end
  end
end

class Check
  require 'uri'
  require 'net/http'
  
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
        if $options.checked_classes.member? uri.class
          begin
            response = Net::HTTP.get_response(uri)
            code = response.code
          rescue
            code = nil
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
        end
      rescue URI::InvalidURIError
        :invalid
      end
    else
      :scheme_ignored
    end
  end
end

class SSOAuth
  def self.get_cookies(url)
    h = {}
    agent = Mechanize.new
    agent.get(url) do |page|
      if page.forms.first && page.forms.first.fields[0].name == "SAMLResponse"
        agent.submit(page.forms.first)
        agent.cookies.each do |c|
          h[c.name] = c.value
        end
      end
    end
    h
  end
end

class Crawler
  def initialize(site)
    @site = site
  end


  def crawl
    LinkCache.flush # only cleared if not recently used
    pre_cleanup
    Anemone.crawl(@site.location, :discard_page_bodies => true) do |anemone|
      @site.log_crawl
      anemone.on_every_page do |page|
        check_links(page) if page.doc
        @site.log_page page.url
      end
    end
    post_cleanup
  end


  private

  def check_links(page)
    links = extract_links(page)
    links.each do |link|
      unless LinkCache.passed? link
        check = Check.new
        problem = check.validate(page, link)
        puts problem
        if problem
          @site.add_broken page.url, link, problem
        end
        LinkCache.add link
        @site.log_link link
      end
    end
  end


  def extract_links(page)
    a = page.doc.css('a')
    a = a.map {|link| link.attribute('href').to_s}
    a.uniq!
    a.delete_if {|link| link =~ /^mailto:/} #remove mailto
    a.map! do |link|
      link.gsub!(' ', '%20')
      if link !~ /^[a-z]+:\/\// #doesn't start with a protocol
        location = "http://#{page.url.host}/"
        link = location + link.gsub(/^\//,'') # make absolute
      else
        link
      end
    end
    a = [] if page.doc.at_xpath("//base") # because, really guys?
    a
  end


  def pre_cleanup
    @site.reset_counters
    @site.flush_temp_blacklist
    @site.flush_issues
  end


  def post_cleanup
  end
end

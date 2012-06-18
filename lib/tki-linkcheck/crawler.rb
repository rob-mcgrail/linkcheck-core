STATIC_EXTENSIONS = %w(flv swf png jpg gif asx zip rar tar 7z gz jar js css dtd xsd ico raw mp3 mp4 wav wmv ape aac ac3 wma aiff mpg mpeg avi mov ogg mkv mka asx asf mp2 m1v m3u f4v pdf doc docx xls ppt pps bin exe rss xml)

class Crawler
  def initialize(site)
    @site = site
  end


  def crawl
    opts = {
      :discard_page_bodies => true,
      :delay => $options.crawl_delay,
      :redirect_limit => 1,
      :depth_limit => 12,
      :accept_cookies => true,
      :cookies => SSOAuth.get_cookies(@site.location),
      :skip_query_strings => true,
      :threads => 1,
    }
    pre_cleanup

    catch(:looping) do
      Anemone.crawl(@site.location, opts) do |anemone|
        @site.log_crawl
        anemone.skip_links_like /%23/, /\/index\.php\//, /\.#{STATIC_EXTENSIONS.join('|')}$/
        anemone.on_every_page do |page|
          if LoopTrap.triggered?
            throw :looping
          end

          Status.set page.url
          puts "On page -> #{page.url}"

          check_links(page) if page.doc

          @site.log_page page.url
          LoopTrap.incr
        end
      end
    end

    post_cleanup
  end


  def check_links(page)
    links = LinkExtract << page
    links.each do |link|
      check = Check.new(page, link)
      problem = check.validate
      @site.log_link link
      if problem
        @site.add_broken page.url, link, problem
      end
    end
  end


  private

  def pre_cleanup
    @site.reset_counters
    @site.flush_temp_blacklist
    @site.flush_issues
    LoopTrap.reset
  end


  def post_cleanup
    Status.clear
  end
end

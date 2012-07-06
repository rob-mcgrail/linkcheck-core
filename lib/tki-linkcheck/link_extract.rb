class LinkExtract
  class << self

    def <<(page)
      require 'uri'
      a = page.doc.css('a')
      a = a.map {|link| link.attribute('href').to_s}

      a.uniq!

      a = remove_cruft(a, page)
      a = absolute_and_clean(a, page)

      a.uniq # ignore duplicates again now all links are absolute
    end


    private

    def remove_cruft(a, page)
      a.delete_if do |link|
        outcome = nil
        $options.permanently_ignore.each do |pattern|
          match = pattern.match(link)
          outcome = match if match
        end
        outcome
      end
      a
    end


    def absolute_and_clean(a, page)
      a.map! do |link|
        if link !~ /^[a-z]+:\/\// # doesn't start with a protocol
          if link =~ /^\// # but does start with a slash ("/thing/1")
            location = "http://#{page.url.host}/"
            link = location + link.gsub(/^\//,'')
          else
            # append page path to relative ("thing/1") url
            location = page.url.to_s
            unless /(\/$)/.match(location)
              location = location + '/'
            end
            link = location + link.gsub(/^\//,'') # make absolute
          end
        else
          link
        end
        link = link.gsub('%23', '#')
      end
    end
  end
end

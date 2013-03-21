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

        if link =~ /^\// # Starts with a slash
            # Make absolute
            location = "http://#{page.url.host}/"
            link = location + link.gsub(/^\//,'')

        elsif link !~ /^[a-z]+:\/\// # has no protocol

          if page.url.to_s =~ /\/$/ # page has a trailing slash
            # append
            location = page.url.to_s
            link = location + link
          else
            # Make absolute
            path = page.url.path.to_s
            extra = path.match /([^\/]+$)/

            if extra
              # Discard extra
              shortened = path.gsub(/#{extra[1]}$/, '')
            end

            # Remove any slashes if needed
            shortened = shortened[1..-1] if shortened && shortened =~ /^\//

            # Assemble absolute link
            link = "http://#{page.url.host}/#{shortened}" + link
          end

        end

        link = link.gsub('%23', '#')
      end
    end
  end
end

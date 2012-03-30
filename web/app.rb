Dir['./web/modules/*.rb'].each {|file| require file }

configure do
  set :root, File.dirname(__FILE__)
  set :lock, true
  set :method_override, true # For HTTP verbs
  set :sessions, false
  set :logging, false # stops annoying double log messages.
  set :static, false # see config.ru for dev mode static file serving
end

configure :development do
  set :raise_errors, true
  set :show_exceptions, true
  set :haml, {:format => :html5, :ugly => false, :escape_html => true}
end

configure :production do
  set :raise_errors, false
  set :show_exceptions, false
  set :haml, {:format => :html5, :ugly => true, :escape_html => true}
end


helpers do
  def partition_by_age(sites, age=1209600)
    partition = sites.partition do |site|
      time = Time.now.to_i - site.last_checked.to_i
      time < age
    end
  end
  
  def tab_cardinalities(site)
    h = {}
    h[:pages] = site.pages_with_brokens_count
    h[:blacklist] = site.blacklist_count
    h[:temp_blacklist] = site.temp_blacklist_count
    h
  end
end 


get '/?' do
  title 'sites'
  partition = partition_by_age(Sites.all)
  puts partition[0].first.location
  @recent = partition[0]
  @old = partition[1]
  haml :sites
end


get '/site/:location/?' do
  location = params[:location].from_slug
  @context = :pages
  @site = Sites.get(location)
  @pages = @site.links_by_problem_by_page
  @tab_cards = tab_cardinalities(@site)
  haml :info_broken
end


get '/site/:location/blacklist?' do
  location = params[:location].from_slug
  @context = :blacklist
  @site = Sites.get(location)
  @links = @site.pages_by_blacklisted_link(:permanent)
  @links.each do |k,v|
    puts 'k: ' + k
    puts v.class
    puts v.length
  end
  @tab_cards = tab_cardinalities(@site)
  haml :info_blacklist
end


get '/site/:location/blacklist/temp?' do
  location = params[:location].from_slug
  @context = :temp_blacklist
  @site = Sites.get(location)
  @links = @site.pages_by_blacklisted_link(:temp)
  @tab_cards = tab_cardinalities(@site)
  haml :info_blacklist
end


post '/blacklist/temp/?' do
  location = params[:site]
  link = params[:link]
  Sites.get(location).temp_blacklist link
  redirect "/site/#{location.to_slug}"
end


post '/blacklist/permanently/?' do
  location = params[:site]
  link = params[:link]
  Sites.get(location).blacklist link
  redirect "/site/#{location.to_slug}"
end


post '/blacklist/premanent/remove/?' do
  location = params[:site]
  link = params[:link]
  Sites.get(location).remove_from_blacklist link
  redirect "/site/#{location.to_slug}/blacklist"
end


post '/blacklist/temp/remove?' do
  location = params[:site]
  link = params[:link]
  Sites.get(location).remove_from_temp_blacklist link
  redirect "/site/#{location.to_slug}/blacklist/temp"
end


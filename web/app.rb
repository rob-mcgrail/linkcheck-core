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
  @tabs = {:broken => 'active'}
  @site = Sites.get(location)
  @pages = @site.links_by_problem_by_page
  haml :info_broken
end


get '/site/:location/blacklist?' do
  location = params[:location].from_slug
  @tabs = {:blacklist => 'active'}
  @site = Sites.get(location)
  @links = @site.links_by_problem_by_page
  haml :info_blacklist
end


get '/site/:location/blacklist/tmp?' do
  location = params[:location].from_slug
  @tabs = {:temp_blacklist => 'active'}
  @site = Sites.get(location)
  @links = @site.links_by_problem_by_page
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


Dir['./web/modules/*.rb'].each {|file| require file }

configure do
  set :root, File.dirname(__FILE__)
#  set :lock, true
  set :sessions, true
  set :logging, false # stops annoying double log messages.
  set :static, false # see config.ru for dev mode static file serving
end

configure :development do
  set :raise_errors, true
  set :show_exceptions, true
  set :pdf, '/usr/bin/wkhtmltopdf'
  set :haml, {:format => :html5, :ugly => false, :escape_html => true}
end

configure :production do
  set :raise_errors, false
  set :show_exceptions, false
  set :pdf, 'xvfb-run -a -s "-screen 0 640x480x16" /usr/bin/wkhtmltopdf' # for debian
  set :haml, {:format => :html5, :ugly => true, :escape_html => true}
end


helpers do
  def tab_cardinalities(site)
    h = {}
    h[:pages] = site.pages_with_brokens_count
    h[:blacklist] = site.blacklist_count
    h[:temp_blacklist] = site.temp_blacklist_count
    h
  end

  def pdf(page, destination)
    # echo "<b>Hello</b> World!" | wkhtmltopdf - foo.pdf --user-style-sheet /url/css.css
    location = params[:location]
    str = "#{settings.pdf} #{request.host}:#{request.port}#{page} #{settings.public_folder}/pdf#{destination}"
    system str
    "/pdf#{destination}"
  end
end


get '/?' do
  title 'sites'
  partition = Sites.partition_by_age
  @recent = partition[0]
  @old = partition[1]
  haml :sites
end


get '/site/:location/?' do
  location = params[:location].from_slug
  title location
  @context = :pages
  @site = Sites.get(location)
  @pages = @site.pages_by_link_by_problem
  @tab_cards = tab_cardinalities(@site)
  haml :info_broken
end


get '/site/:location/blacklist/?' do
  location = params[:location].from_slug
  title location
  @context = :blacklist
  @site = Sites.get(location)
  @links = @site.pages_by_blacklisted_link(:permanent)
  @tab_cards = tab_cardinalities(@site)
  haml :info_blacklist
end


get '/site/:location/blacklist/temp/?' do
  location = params[:location].from_slug
  title location
  @context = :temp_blacklist
  @site = Sites.get(location)
  @links = @site.pages_by_blacklisted_link(:temp)
  @tab_cards = tab_cardinalities(@site)
  haml :info_blacklist
end


get '/sites/manage/?' do
   title 'manage sites'
   @sites = Sites.all
   @inactive_sites = Sites.inactive
   @admin = true
   haml :admin
end


get '/sites/add' do
  title 'add'
  haml :add
end


get '/site/:location/pdf' do
  location = params[:location]
  @pdf_url = pdf("/site/#{location}", "/#{Time.now.to_i}.pdf")
  redirect @pdf_url
end



post '/ajax/count/pages' do
  @site = Sites.get(params[:site])
  status 200
  body @site.pages_with_brokens_count.to_s
end


post '/ajax/count/temp' do
  @site = Sites.get(params[:site])
  status 200
  body @site.temp_blacklist_count.to_s
end


post '/ajax/count/blacklist' do
  @site = Sites.get(params[:site])
  status 200
  body @site.blacklist_count.to_s
end


post '/sites/add' do
  site = Sites.create(:location => params[:location])
  if site.is_a? Sites
    flash[:success] = "You have created a new site <strong>#{site.location}</strong>"
    redirect '/sites/manage'
  else
    flash[:error] = "There was a problem creating the new site."
    redirect '/sites/manage'
  end
end


post '/sites/manage/deactivate/?' do
   Sites.deactivate(params[:site])
   redirect '/sites/manage'
end


post '/sites/manage/activate/?' do
   Sites.activate(params[:site])
   redirect '/sites/manage'
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

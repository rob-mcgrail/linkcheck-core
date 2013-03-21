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
  def pdf(location)
    require 'open3'
    @context = :pages
    @site = Sites.get(location)
    @problems = @site.pages_by_link_by_problem

    tmpfile = Tempfile.new(['pdf-source', '.html'])
    tmpfile.write(haml :'pdf/pdf', :layout => false)

    command = "#{settings.pdf} -q #{tmpfile.path} - --user-style-sheet #{settings.public_folder}/css/pdf.css"

    pdf, err = Open3.popen3(command) do |stdin, stdout, stderr|
      stdout.binmode
      stderr.binmode
      [stdout.read, stderr.read]
    end
  end
end

get '/test/:location/?' do
  location = params[:location].from_slug
  title location
  @context = :pages
  @site = Sites.get(location)
  @problems = @site.pages_by_link_by_problem
  haml :'pdf/pdf'
end

get '/?' do
  title 'sites'
  partition = Sites.partition_by_age
  @recent = partition[0]
  @old = partition[1]
  haml :sites
end

# Route for API
get '/site/:location.json?' do
  location = params[:location].from_slug
  title location
  @context = :pages
  @site = Sites.get(location)
  @problems = @site.pages_by_link_by_problem

  content_type :json
  @problems.to_json
end


get '/site/:location/?' do
  location = params[:location].from_slug
  title location
  @context = :pages
  @site = Sites.get(location)
  @problems = @site.pages_by_link_by_problem
  haml :info_broken
end


get '/site/:location/blacklist/?' do
  location = params[:location].from_slug
  title location
  @context = :blacklist
  @site = Sites.get(location)
  @links = @site.pages_by_blacklisted_link(:permanent)
  haml :info_blacklist
end


get '/site/:location/blacklist/temp/?' do
  location = params[:location].from_slug
  title location
  @context = :temp_blacklist
  @site = Sites.get(location)
  @links = @site.pages_by_blacklisted_link(:temp)
  haml :info_blacklist
end


get '/sites/manage/?' do
   title 'manage sites'
   @sites = Sites.all
   @inactive_sites = Sites.inactive
   @admin = true
   haml :manage
end


get '/sites/add' do
  title 'add'
  haml :add
end



get '/admin/?' do
  title 'admin'
  @admin = true
  haml :admin
end


post '/purge_orphaned_blacklist_items' do
  Sites.purge_orphaned_blacklist_items
  redirect '/admin'
end


get '/summary_report.csv' do
  [200, {'Content-Type' => 'text/csv'}, Sites.summary_report]
end


get '/site/:location/pdf' do
  location = params[:location].from_slug
  @pdf = pdf(location)
  [200, {'Content-Type' => 'application/pdf'}, @pdf]
end


get '/check-status' do
  status = $redis.get("#{$options.global_prefix}:status")
  if status
    'Checking ' + status[0..70] + '...'
  else
    'Not running'
  end
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


post '/blacklist/temp/remove/?' do
  location = params[:site]
  link = params[:link]
  Sites.get(location).remove_from_temp_blacklist link
  redirect "/site/#{location.to_slug}/blacklist/temp"
end


post '/sites/reported/?' do
  location = params[:site]
  change = params[:change]
  if change == 'add'
    Sites.get(location).is_reported
  elsif change == 'remove'
    Sites.get(location).not_reported
  else
    flash[:error] = "There was an error changing site status."
  end
  redirect "/site/#{location.to_slug}"
end

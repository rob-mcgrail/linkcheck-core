get '/?' do
  title 'sites'
  sites = Sites.all
  partition = sites.partition do |site|
    time = Time.now.to_i - site.last_checked.to_i
    time < 1209600
  end
  @recent = partition[0]
  @old = partition[1]
  haml :sites
end


get '/site/:location/?' do
  location = params[:location].un_slug
  @site = Sites.get(location)
  @pages = @site.links_by_problem_by_page
  haml :info
end


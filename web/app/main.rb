get '/?' do
  title 'sites'
  @sites = Sites.all
  haml :sites
end

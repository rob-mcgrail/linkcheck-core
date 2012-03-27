get '/?' do
  title 'sites'
  flash[:success] = '<strong>Everything</strong> is fine.'
  haml :main
end

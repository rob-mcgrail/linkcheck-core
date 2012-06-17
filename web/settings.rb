configure do
  set :method_override, true # For HTTP verbs
  set :sessions, true
  set :logging, false # stops annoying double log messages.
  set :static, false # see config.ru for dev mode static file serving
  set :redis, 1 # redis database
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

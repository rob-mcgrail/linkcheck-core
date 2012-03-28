require 'rubygems'
require 'bundler'

Bundler.require(:web, :default)

require './lib/tki-linkcheck'
require './web/app'

# Rack configuration

# Serve static files in dev 

if settings.development?
  use Rack::Static, :urls => ['/css', '/img', '/js', '/less', '/robots.txt', '/favicons.ico'], :root => "web/public"
end

# Authentication middleware
# https://github.com/hassox/warden/wiki/overview

# Run

run Sinatra::Application

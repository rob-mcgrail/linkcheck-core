require 'rubygems'
require 'bundler'

Bundler.require(:web, :default)

require './lib/tki-linkcheck'
require './web/app'

# Rack configuration

# Serve static files in dev

if settings.development?
  use Rack::Static, :urls => ['/css', '/img', '/js', '/less', '/pdf', '/robots.txt', '/favicons.ico'], :root => "web/public"
end

use PDFKit::Middleware

run Sinatra::Application

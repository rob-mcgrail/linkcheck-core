Bundler.require(:default)

require './settings'

Dir['./modules/*.rb'].each {|file| require file }
Dir['./app/*.rb'].each {|file| require file }

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require './config'
require './lib/tki-linkcheck/redis'
require './lib/tki-linkcheck/check'
require './lib/tki-linkcheck/link_cache'
require './lib/tki-linkcheck/site'
require './lib/tki-linkcheck/crawler'

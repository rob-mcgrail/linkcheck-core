require './web/settings'

Dir['./web/modules/*.rb'].each {|file| require file }
Dir['./web/app/*.rb'].each {|file| require file }

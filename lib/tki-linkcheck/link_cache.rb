class LinkCache
  @@key = "#{$options.global_prefix}:checked"
  
  def self.checked?(link)
    $redis.sismember @@key, link
  end
  
  
  def self.add(link)
    if link =~ /^http:/
      $redis.sadd @@key, link
    end
  end
  
  
  def self.flush
    $redis.del @@key
  end
end

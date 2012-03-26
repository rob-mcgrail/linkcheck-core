class LinkCache

  def self.checked?(link)
    $redis.sismember "#{$options.global_prefix}:checked", link
  end
  
  
  def self.add(link)
    if link =~ /^http:/
      $redis.sadd "#{$options.global_prefix}:checked", link
    end
  end
  
  
  def self.flush
    $redis.del "#{$options.global_prefix}:checked"
  end
  
end

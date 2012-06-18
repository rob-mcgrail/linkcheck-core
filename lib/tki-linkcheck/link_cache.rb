class LinkCache
  @@keys = {
    :response => "#{$options.global_prefix}:response:"
  }

#  def self.checked?(link)
#    $redis.sismember @@keys[:checked], link
#  end

  def self.get(link)
    response = $redis.get @@keys[:response] + link
  end


  def self.add(link, code) # set expiry based on location...
    $redis.set @@keys[:response] + link, code
    $redis.expire @@keys[:response] + link, $options.expiry
  end


#  def self.flush_if_stale
#    recency = Time.now - @@time
#    if recency > $options.linkcache_time
#      self.flush
#    end
#  end


  def self.flush
    cache_keys = $redis.keys @@keys[:response] + "*"
    puts cache_keys
    cache_keys.each do |k|
      $redis.del k
    end
  end
end

class LinkCache
  @@keys = {
    :checked => "#{$options.global_prefix}:cached",
    :response => "#{$options.global_prefix}:response:"
  }
  @@time = Time.now
  @@context = nil

#  def self.checked?(link)
#    $redis.sismember @@keys[:checked], link
#  end

  def self.set_context(location)
    @@context = location
  end

  def self.get(link)
    response = $redis.get @@keys[:response] + link
  end


  def self.add(link, code) # set expiry based on location...
    $redis.set @@keys[:response] + link, code
    if /^#{Regexp.escape(@@context.to_s)}/.match(link)
      $redis.expire @@keys[:response] + link, $options.long_expiry
    else
      $redis.expire @@keys[:response] + link, $options.short_expiry
    end
  end


#  def self.flush_if_stale
#    recency = Time.now - @@time
#    if recency > $options.linkcache_time
#      self.flush
#    end
#  end


  def self.flush
    self.delete_responses
    $redis.del @@keys[:checked]
  end


  private


  def self.delete_responses
    $redis.smembers(@@keys[:checked]).each do |k|
      $redis.del @@keys[:response] + k
    end
  end
end

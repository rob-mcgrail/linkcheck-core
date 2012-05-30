class LinkCache
  @@keys = {
    :checked => "#{$options.global_prefix}:cached",
    :response => "#{$options.global_prefix}:response:"
  }
  @@time = Time.now

  def self.checked?(link)
    $redis.sismember @@keys[:checked], link
  end


  def self.get(link)
    response = $redis.get @@keys[:response] + link
    if response == "" || nil
      nil
    else
      response.to_sym if response
    end
  end


  def self.add(link, code)
    if link =~ /^http|^https/
      @@time = Time.now
      $redis.sadd @@keys[:checked], link
      $redis.set @@keys[:response] + link, code
    end
  end


  def self.flush_if_stale
    recency = Time.now - @@time
    if recency > $options.linkcache_time
      self.delete_responses
      $redis.del @@keys[:checked]
    end
  end


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

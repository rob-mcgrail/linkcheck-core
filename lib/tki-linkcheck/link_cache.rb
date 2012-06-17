class LinkCache
  @@key = "#{$options.global_prefix}:checked"
  @@time = Time.now

  def self.passed?(link)
    $redis.sismember @@key, link
  end


  def self.add(link)
    if link =~ /^http|^https/
      @@time = Time.now
      $redis.sadd @@key, link
    end
  end


  def self.flush
    recency = Time.now - @@time
    if recency > $options.linkcache_time
      $redis.del @@key
    end
  end


  def self.force_flush
    $redis.del @@key
  end
end

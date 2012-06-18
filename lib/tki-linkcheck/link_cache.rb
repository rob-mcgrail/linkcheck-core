class LinkCache
  @@keys = {
    :response => "#{$options.global_prefix}:response:"
  }


  def self.get(link)
    response = $redis.get @@keys[:response] + link
  end


  def self.add(link, code)
    $redis.set @@keys[:response] + link, code
    $redis.expire @@keys[:response] + link, $options.expiry
  end


  def self.flush
    cache_keys = $redis.keys @@keys[:response] + "*"
    cache_keys.each do |k|
      $redis.del k
    end
  end
end

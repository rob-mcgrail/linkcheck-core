class Status
  def self.set(status)
    $redis.set "#{$options.global_prefix}:status", "#{status}"
    $redis.expire "#{$options.global_prefix}:status", 120
  end


  def self.clear
    $redis.del "#{$options.global_prefix}:status"
  end
end

class LoopTrap
  def self.incr
    $redis.incr "#{$options.global_prefix}:looptrap"
  end

  def self.count
    $redis.get "#{$options.global_prefix}:looptrap"
  end

  def self.triggered?
    if self.count == $options.crawl_limit
      true
    else
      nil
    end
  end

  def self.flush
    $redis.del "#{$options.global_prefix}:looptrap"
  end
end

class Sites
  def self.create(properties = {})
    if properties.has_key? :location
      $redis.sadd "#{$options.global_prefix}:sites", properties[:location]
      properties.each do |k,v|
        $redis.hset "#{$options.global_prefix}:#{properties[:location]}", k.to_s, v.to_s
      end
      self.get(properties[:location])
    end
  end
  
  
  def self.get(location)
    if $redis.sismember "#{$options.global_prefix}:sites", location
      self.new(location)
    end
  end
  
  
  def initialize(location)
    properties = $redis.hgetall "#{$options.global_prefix}:#{location}"
    
    properties.each do |k,v|
      instance_variable_set("@#{k}".to_sym, v)
      self.class.__send__(:attr_accessor, "#{k}".to_sym)
    end
    
    @prefix = "#{$options.global_prefix}:#{@location}"
    
    @key = {
      :pages => "#{@prefix}:pages",
      :page => "#{@prefix}:page",
      :problem => "#{@prefix}:problem",
      :problems => "#{@prefix}:problems",
      :blacklist => "#{@prefix}:blacklist",
      :temp_blacklist => "#{@prefix}:blacklist:temp",
      :page_count => "#{@prefix}:count:pages",
      :broken_count => "#{@prefix}:count:broken",
      :check_count => "#{@prefix}:count:checked",
    }
  end


  def add_broken(page, link, problem)
    $redis.multi do
      $redis.sadd @key[:pages], page
      $redis.sadd @key[:page] + ":#{page}", link
      $redis.sadd @key[:problems], problem.to_s
      $redis.sadd @key[:problem] + ":#{problem}", link
      $redis.incr @key[:broken_count]
    end
  end


  def log_link(link)
    $redis.incr @key[:check_count]
    LinkCache.add link
  end
  
  
  def log_page(page)
    $redis.incr @key[:page_count]
  end
  
  
  def blacklist(link)
    $redis.sadd @key[:blacklist], link
  end
  
  
  def temp_blacklist(link)
    $redis.sadd @key[:temp_blacklist], link
  end
  
  
  def remove_from_blacklist(link)
    $redis.srem @key[:blacklist], link
  end
  
  
  def reset_counters
    $redis.set @key[:page_count], 0
    $redis.set @key[:check_count], 0
    $redis.set @key[:broken_count], 0
  end
  
  
  def flush_temp_blacklist
    $redis.del @key[:temp_blacklist]
  end
  
  
  def flush_issues
    setpairs = {
      @key[:pages] => @key[:page],
      @key[:problems] => @key[:problem],
    }
    flush_sets setpairs
  end
  
  
  private
  
  def flush_sets(setpairs)
    setpairs.each do |superset, set_prefix|
      keys = $redis.smembers superset
      keys.each do |k|
        $redis.del set_prefix + ":#{k}"
      end
      $redis.del superset
    end
  end
end

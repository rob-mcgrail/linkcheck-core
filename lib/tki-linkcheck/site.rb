class Site
  attr_reader :address
  
  def initialize(address)
    @address = address
    @prefix = "#{$options.global_prefix}:#{@address}"
    @key = {
      :pages => "#{@prefix}:pages",
      :page => "#{@prefix}:page",
      :problem => "#{@prefix}:problem",
      :problems => "#{@prefix}:problems",
      :blacklist => "#{@prefix}:blacklist",
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
  
  
  def reset_counters
    $redis.set @key[:page_count], 0
    $redis.set @key[:check_count], 0
    $redis.set @key[:broken_count], 0
  end
  
  
  def flush_issues
    setpairs = {
      @key[:issue_pages] => @key[:page],
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




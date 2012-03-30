class Sites
  def self.create(properties = {})
    if properties.has_key? :location
      # normalize location strings
      properties[:location].gsub!(/\/$/, '')
      # add to sites list
      $redis.sadd "#{$options.global_prefix}:sites", properties[:location]
      properties.each do |k,v|
        # stick all properties key pairs in a redis hash
        $redis.hset "#{$options.global_prefix}:#{properties[:location]}", k.to_s, v.to_s
      end
      self.get(properties[:location])
    end
  end
  
  
  def self.all
    keys = $redis.smembers "#{$options.global_prefix}:sites"
    sites = []
    keys.each do |site|
      sites << self.get(site)
    end
    sites
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
      :links => "#{@prefix}:links",
      :link => "#{@prefix}:link",
      :problem => "#{@prefix}:problem",
      :problems => "#{@prefix}:problems",
      :blacklist => "#{@prefix}:blacklist",
      :temp_blacklist => "#{@prefix}:blacklist:temp",
      :page_count => "#{@prefix}:count:pages",
      :broken_count => "#{@prefix}:count:broken",
      :broken_page_count => "#{@prefix}:count:broken_pages",
      :check_count => "#{@prefix}:count:checked",
    }
  end
  
  
  def method_missing(m, *args, &block)
    nil
  end
  
  
  def broken_links_count
    s = $redis.get @key[:broken_count]
    if s
      s.to_i
    else
      nil
    end
  end # test for int
  
  
  def pages_checked_count
    s = $redis.get @key[:page_count]
    if s
      s.to_i
    else
      nil
    end
  end # test for int


  def links_checked_count
    s = $redis.get @key[:check_count]
    if s
      s.to_i
    else
      nil
    end
  end
    
  
  def pages_with_brokens_count
    s = $redis.get @key[:broken_page_count]
    if s
      s.to_i
    else
      nil
    end
  end


  def links_by_problem_by_page
    # returns {'page' => {'problem' => ['link', 'link']}}
    h = {}
    # get pages for the site
    $redis.smembers(@key[:pages]).each do |page|
      h[page] = {}
      # flush tmp keys
      $redis.del 'tmp:exclude', 'tmp:cleaned'
      # get combined blacklist 
      $redis.sunionstore 'tmp:exclude', @key[:blacklist], @key[:temp_blacklist]
      # store links not in blacklist
      $redis.sdiffstore 'tmp:cleaned', @key[:page] + ":#{page}", 'tmp:exclude' 
      problems = $redis.smembers(@key[:problems])
      # problems.delete('unknown')
      problems.each do |problem|
        # for each problem type, store links also in that set
        h[page][problem] = $redis.sinter 'tmp:cleaned', @key[:problem] + ":#{problem}"
      end
    end
    h
  end
  
  
  def pages_by_blacklisted_links_by_problem(mode = :permanent)
     # returns {'problem' => {'link' => ['page', 'page']}} 
    opts = {
      :permanent => @key[:blacklist], 
      :temp => @key[:temp_blacklist]
    }
    h = {}
    # cycle through problems
    $redis.smembers(@key[:problems]).each do |problem|
        # cycle through links belonging to a problem and the blacklist
        $redis.sinter(opts[mode], @key[:problem] + ":#{problem}").each do |link|
          h[problem] = {}
          h[problem][link] = $redis.smembers @key[:link] + ":#{link}"  
        end
    end
    h
  end


  def add_broken(page, link, problem)
    # increment broken page count if not already counted
    unless $redis.sismember @key[:pages], page
      $redis.incr @key[:broken_page_count]
      $redis.sadd @key[:pages], page
    end
    $redis.multi do
      $redis.sadd @key[:page] + ":#{page}", link
      $redis.sadd @key[:links], link
      $redis.sadd @key[:link] + ":#{link}", page
      $redis.sadd @key[:problems], problem.to_s
      $redis.sadd @key[:problem] + ":#{problem}", link
    end
    # increment broke count if not blacklisted
    unless $redis.sismember @key[:blacklist], link
      $redis.incr @key[:broken_count]
    end
  end


  def log_link(link)
    $redis.incr @key[:check_count]
  end
  
  
  def log_page(page)
    $redis.incr @key[:page_count]
  end
  
  
  def log_crawl
    $redis.hset "#{@prefix}", 'last_checked', Time.now.to_i
  end
  
  
  def blacklist(link)
    $redis.sadd @key[:blacklist], link
    $redis.decr @key[:broken_count]
    adjust_broken_pages_count_by_blacklist(link, :adding)
  end
  
  
  def temp_blacklist(link)
    $redis.sadd @key[:temp_blacklist], link
    $redis.decr @key[:broken_count]
    adjust_broken_pages_count_by_blacklist(link, :adding)
  end
  
  
  def remove_from_blacklist(link)
    $redis.srem @key[:blacklist], link
    $redis.incr @key[:broken_count]
    adjust_broken_pages_count_by_blacklist(link, :removing)
  end
  
  
  def remove_from_temp_blacklist(link)
    $redis.srem @key[:temp_blacklist], link
    $redis.incr @key[:broken_count]
    adjust_broken_pages_count_by_blacklist(link, :removing)
  end
  
  
  def reset_counters
    $redis.set @key[:page_count], 0
    $redis.set @key[:check_count], 0
    $redis.set @key[:broken_count], 0
    $redis.set @key[:broken_page_count], 0
  end
  
  
  def flush_temp_blacklist
    $redis.del @key[:temp_blacklist]
  end
  
  
  def flush_issues
    setpairs = {
      @key[:pages] => @key[:page],
      @key[:links] => @key[:link],
      @key[:problems] => @key[:problem],
    }
    flush_sets setpairs
  end
  
  
  private
  
  def adjust_broken_pages_count_by_blacklist(link, context = :adding)
    # make combined blacklist
    $redis.sunionstore 'tmp:exclude', @key[:blacklist], @key[:temp_blacklist]
    # get pages containing this link
    $redis.smembers(@key[:link] + ":#{link}").each do |page|
      # store non-blacklist links for pages 
      $redis.sdiffstore 'tmp:remainder', @key[:page] + ":#{page}", 'tmp:exclude'
      i = $redis.scard('tmp:remainder')
      $redis.del 'tmp:remainder'
      case context
      when :adding
        # if that is an empty set, decrement the broken page count
        $redis.decr @key[:broken_page_count] if i == 0
      when :removing
        # if that is a set of 1, increment the broken page count
        $redis.incr @key[:broken_page_count] if i == 1
      end
    end
    $redis.del 'tmp:exclude'
  end
  
  
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

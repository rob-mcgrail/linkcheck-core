class Sites
  def self.create(properties = {})
    if properties.has_key? :location
      if properties[:location] =~ /^http/
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
  end


  def self.all
    keys = $redis.smembers "#{$options.global_prefix}:sites"
    keys.sort! { |a,b| a <=> b }
    sites = []
    keys.each do |site|
      sites << self.get(site)
    end
    sites
  end


  def self.get(location)
    self.new(location)
  end


  def self.deactivate(location)
    $redis.multi do
      $redis.srem "#{$options.global_prefix}:sites", location
      $redis.sadd "#{$options.global_prefix}:inactive:sites", location
    end
  end


  def self.activate(location)
    $redis.multi do
      $redis.srem "#{$options.global_prefix}:inactive:sites", location
      $redis.sadd "#{$options.global_prefix}:sites", location
    end
  end


  def self.inactive
    keys = $redis.smembers "#{$options.global_prefix}:inactive:sites"
    sites = []
    keys.each do |site|
      sites << self.get(site)
    end
    sites
  end


  def self.partition_by_age(age=1209600)
    sites = Sites.all
    partition = sites.partition do |site|
      time = Time.now.to_i - site.last_checked.to_i
      time < age
    end
  end


  def self.summary_report(age=4838400)
    FasterCSV.generate do |csv|
      csv << ['Community', 'Pages', 'Checked', 'Broken']
      Sites.all.each do |site|
        time = Time.now.to_i - site.last_checked.to_i
        if time < age
          a = [site.location]
          a << site.pages_checked_count
          a << site.links_checked_count
          a << site.broken_links_count
          csv << a
        end
      end
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
      :page => "#{@prefix}:page:",
      :links => "#{@prefix}:links",
      :link => "#{@prefix}:link:",
      :problems => "#{@prefix}:problems",
      :problem => "#{@prefix}:problem:",
      :blacklist => "#{@prefix}:blacklist",
      :temp_blacklist => "#{@prefix}:blacklist:temp",
      :page_count => "#{@prefix}:count:pages",
      :broken_count => "#{@prefix}:count:broken",
      :check_count => "#{@prefix}:count:checked",
    }
  end


  def method_missing(m, *args, &block)
    nil
  end


  def add_broken(page, link, problem)
    blacklisted = $redis.sismember @key[:blacklist], link
    already_added = $redis.sismember @key[:links], link
    $redis.multi do
      $redis.sadd @key[:pages], page.to_s
      $redis.sadd @key[:page] + page.to_s, link.to_s
      $redis.sadd @key[:links], link.to_s
      $redis.sadd @key[:link] + link.to_s, page.to_s
      $redis.sadd @key[:problems], problem.to_s
      $redis.sadd @key[:problem] + problem.to_s, link.to_s
    end
    # increment broken count if not blacklisted
    unless blacklisted || already_added
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
    unless $redis.sismember(@key[:blacklist], link)
      $redis.sadd @key[:blacklist], link
      $redis.decr @key[:broken_count]
    end
  end


  def temp_blacklist(link)
    unless $redis.sismember(@key[:temp_blacklist], link)
      $redis.sadd @key[:temp_blacklist], link
      $redis.decr @key[:broken_count]
    end
  end


  def remove_from_blacklist(link)
    if $redis.sismember(@key[:blacklist], link)
      $redis.srem @key[:blacklist], link
      $redis.incr @key[:broken_count]
    end
  end


  def remove_from_blacklist_silently(link)
    if $redis.sismember(@key[:blacklist], link)
      $redis.srem @key[:blacklist], link
    end
  end


  def remove_from_temp_blacklist(link)
    if $redis.sismember(@key[:temp_blacklist], link)
      $redis.srem @key[:temp_blacklist], link
      $redis.incr @key[:broken_count]
    end
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
      @key[:links] => @key[:link],
      @key[:problems] => @key[:problem],
    }
    flush_sets setpairs
  end


  def links_by_problem_by_page
    # returns {'page' => {'problem' => ['link', 'link']}}
    h = {}
    # get pages for the site
    $redis.smembers(@key[:pages]).each do |page|
      # flush tmp keys
      $redis.del 'tmp:exclude', 'tmp:cleaned'
      # get combined blacklist
      $redis.sunionstore 'tmp:exclude', @key[:blacklist], @key[:temp_blacklist]
      # store links not in blacklist
      $redis.sdiffstore 'tmp:cleaned', @key[:page] + page, 'tmp:exclude'
      if $redis.scard('tmp:cleaned') > 0
        h[page] = {}
        problems = $redis.smembers(@key[:problems])
        problems.each do |problem|
          # for each problem type, store links also in that set
          h[page][problem] = $redis.sinter 'tmp:cleaned', @key[:problem] + problem
        end
      end
    end
    h
  end


  def pages_by_link_by_problem
    # returns {'problem' => {'link' => ['page', 'page']}}
    h = {}
    # get problems for the site
    $redis.smembers(@key[:problems]).each do |problem|
      h[problem] = {}
      # flush tmp keys
      $redis.del "tmp:exclude:#{@location}", "tmp:cleaned:#{@location}"
      # get combined blacklist
      $redis.sunionstore "tmp:exclude:#{@location}", @key[:blacklist], @key[:temp_blacklist]
      # store links not in blacklist
      $redis.sdiffstore "tmp:cleaned:#{@location}", "#{@key[:problem]}#{problem}", "tmp:exclude:#{@location}"
      if $redis.scard("tmp:cleaned:#{@location}") > 0
        $redis.smembers("tmp:cleaned:#{@location}").each do |link|
          h[problem][link] = $redis.smembers(@key[:link] + link)
        end
      end
    end
    h
  end


  def pages_by_blacklisted_link(mode = :permanent)
     # returns {'link' => ['page', 'page']}
    opts = {
      :permanent => @key[:blacklist],
      :temp => @key[:temp_blacklist]
    }
    h = {}
    $redis.smembers(opts[mode]).each do |link|
      a = $redis.smembers @key[:link] + link
      # ensure there's an array, instead of nil or 0
      a = [] unless a.kind_of? Array
      h[link] = a
    end
    h
  end


  def broken_links_count
    sanitized_count $redis.get @key[:broken_count]
  end


  def pages_checked_count
    sanitized_count $redis.get @key[:page_count]
  end


  def links_checked_count
    sanitized_count $redis.get @key[:check_count]
  end


  def sanitized_count(v)
    if v
      v.to_i
    else
      nil
    end
  end


  def blacklist_count
    $redis.scard @key[:blacklist]
  end


  def temp_blacklist_count
    $redis.scard @key[:temp_blacklist]
  end


  private


  def flush_sets(setpairs)
    setpairs.each do |superset, set_prefix|
      keys = $redis.smembers superset
      keys.each do |k|
        $redis.del set_prefix + k
      end
      $redis.del superset
    end
  end


  def self.purge_orphaned_blacklist_items
    Sites.all.each do |location|
      @site = Sites.new('location')
      @site.purge_orphaned_blacklist_items
    end
  end


  def purge_orphaned_blacklist_items
    $redis.smembers(@key[:blacklist]).each do |link|
      i = $redis.scard @key[:link] + link
      unless i > 0
        self.remove_from_blacklist_silently link
      end
    end
  end
end

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
    R.multi do
      R.sadd @key[:pages], page
      R.sadd @key[:page] + ":#{page}", link
      R.sadd @key[:problems], problem.to_s
      R.sadd @key[:problem] + ":#{problem}", link
      R.incr @key[:broken_count]
    end
  end


  def log_link(link)
    R.incr @key[:check_count]
    LinkCache.add link
  end
  
  
  def log_page(page)
    R.incr @key[:page_count]
  end
  
  
  def reset_counters
    R.set @key[:page_count], 0
    R.set @key[:check_count], 0
    R.set @key[:broken_count], 0
  end
  
  
  def flush_issues
    pages = R.smembers @key[:issue_pages]
    pages.each do |k|
      R.del @key[:page] + ":#{k}"
    end
    problems = R.smembers @key[:problems]
    problems.each do |k|
      R.del @key[:problem] + ":#{k}"
    end
    R.del @key[:issue_pages]
    R.del @key[:problems]
  end
end


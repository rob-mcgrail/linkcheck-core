class LinkCache
  def self.checked?(link)
    R.sismember "#{$options.global_prefix}:checked", link
  end
  
  
  def self.add(link)
    if link =~ /^http:/
      R.sadd "#{$options.global_prefix}:checked", link
    end
  end
  
  
  def self.flush
    R.del "#{$options.global_prefix}:checked"
  end
end

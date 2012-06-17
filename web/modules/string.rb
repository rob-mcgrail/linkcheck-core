# Helpers added to String

class String
  def parameterize(delimeter = '-')
    self.gsub(/[^a-z0-9\-_!?]+/i, delimeter).downcase
  end
  
  def encrypt
    BCrypt::Password.create(self)
  end

  def make_matchable
    BCrypt::Password.new(self)
  end
  
  def to_time
    Time.at(self.to_i).strftime('%a %e %b %Y')
  end
  
  def to_slug
    self.gsub('http://', '').gsub('.', '-dot-')
  end
  
  def from_slug
    'http://' + self.gsub('-dot-', '.')
  end
  
  def proper_case
    self.slice(0,1).capitalize + self.slice(1..-1)
  end
  
  def plural
    self + 's'
  end
end

helpers do
  def title(arg)
    sitename = 'Linkcheck'
    if arg
      sitename = sitename + ' | ' + arg
    end
    @title = sitename
  end
end

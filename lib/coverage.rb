module Coverage
  
  def self.status(coverage)
    if coverage.nil?
      :none
    elsif coverage > 90
      :good
    elsif coverage > 75
      :fair
    else
      :bad
    end
  end
  
end
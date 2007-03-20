# TODO: move unit tests for this functionality from ApplicationHelperTest to a unit test for the class

class DurationFormatter

  def initialize(duration)
    @duration = duration
    @minutes, @seconds = duration.divmod(60)
    @hours, @minutes = @minutes.divmod(60)
  end


  def general
    if @hours >= 1 and @minutes == 0
      "#{@hours} #{hours_label}"
    elsif @hours >= 1
      "#{@hours} #{hours_label} #{@minutes} #{minutes_label}"
    elsif @minutes >= 1
      "#{@minutes} #{minutes_label}"
    else
      "#{@seconds} #{seconds_label}"
    end
  end

end

def precise
  result = []
  result << "#{@hours} #{hours_label}" unless @hours == 0
  result << "#{@minutes} #{minutes_label}" unless @minutes == 0
  result << "#{@seconds} #{seconds_label}" unless @seconds == 0 and @duration != 0
  result.join(" and ")
end

def hours_label
  @hours == 1 ? hours_label = "hour" : hours_label = "hours"
end

def minutes_label
  @minutes == 1 ? 'minute' : 'minutes'
end

def seconds_label
  @seconds == 1 ? 'second' : 'seconds'
end

def method_missing(format, *args)
  raise "Unknown duration format #{format.inspect}"
end

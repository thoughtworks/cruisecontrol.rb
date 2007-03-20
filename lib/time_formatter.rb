# TODO: move unit tests for this functionality from ApplicationHelperTest to a unit test for the class

class TimeFormatter
end

class << TimeFormatter

  def human(time)
    now = Time.now
    this_year = now.beginning_of_year
    today = now.beginning_of_day
    tomorrow = 1.day.since(today)

    format =
      case(time)
      when Time.at(0)...this_year then '%d %b %y'
      when this_year...today then '%d %b'
      when today...tomorrow then '%H:%M'
      else '%Y-%m-%d %H:%M:%S ?future?'
      end
    remove_leading_zero(time.strftime(format))
  end

  def iso(time)
    time.strftime('%Y-%m-%d %H:%M:%S')
  end

  def iso_date(time)
    time.strftime('%Y-%m-%d')
  end

  def verbose(time)
    remove_leading_zero(time.strftime('%I:%M %p on %d %B %Y'))
  end

  def round_trip_local(time)
    time.strftime('%Y-%m-%dT%H:%M:%S.0000000-00:00') # yyyy'-'MM'-'dd'T'HH':'mm':'ss.fffffffK)
  end

  def rss(time)
    time.getgm.strftime('%a, %d %b %Y %H:%M:%S Z')
  end

  def method_missing(method, *args)
    raise "Unknown time format #{method.inspect}"
  end

  def remove_leading_zero(string)
    string.gsub(/^0(\d:\d\d|\d )/, '\1')
  end
  
end

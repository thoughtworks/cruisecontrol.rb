class TimeFormatter
  def initialize(time)
    @time = time
  end

  def human
    now = Time.now
    this_year = now.beginning_of_year
    today = now.beginning_of_day
    tomorrow = 1.day.since(today)

    format = '%Y-%m-%d %H:%M:%S ?future?'
    format = '%d %b %y' if @time >= Time.at(0) && @time < this_year
    format = '%d %b'    if @time >= this_year  && @time < today
    format = '%H:%M'    if @time >= today      && @time < tomorrow

    remove_leading_zero(@time.strftime(format))
  end

  def iso
    @time.strftime('%Y-%m-%d %H:%M:%S')
  end

  def iso_date
    @time.strftime('%Y-%m-%d')
  end

  def verbose
    remove_leading_zero(@time.strftime('%I:%M %p on %d %B %Y'))
  end

  def round_trip_local
    @time.strftime('%Y-%m-%dT%H:%M:%S.0000000%z') # yyyy'-'MM'-'dd'T'HH':'mm':'ss.fffffffK)
  end

  def rss
    @time.getgm.strftime('%a, %d %b %Y %H:%M:%S Z')
  end

  def method_missing(method, *args)
    raise "Unknown time format #{method.inspect}"
  end

  private
    def remove_leading_zero(string)
      string.gsub(/^0(\d:\d\d|\d )/, '\1')
    end
end

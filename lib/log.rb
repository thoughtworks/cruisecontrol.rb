class Log

  def self.verbose=(verbose)
    @verbose = verbose
  end

  def self.event(description, severity = :info)
    Log.send(severity.to_sym, "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{description}")
    puts "EVENT - #{description}" if @verbose
  end

  def self.method_missing(method, *args, &block)
    RAILS_DEFAULT_LOGGER.send(method, *args, &block)
    puts "#{method} - #{args}" if @verbose
  end
  
end
class Log

  def self.verbose=(verbose)
    @verbose = verbose
  end

  def self.event(description, severity = :info)
    message = "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{description}"
    Log.send(severity.to_sym, message)
    if @verbose
      if severity == :error or severity == :fatal 
        STDERR.puts "[#{severity}] #{message}"
      else 
        puts "[#{severity}] #{message}"
      end
    end
  end

  def self.method_missing(method, *args, &block)
    RAILS_DEFAULT_LOGGER.send(method, *args, &block)
    puts "[#{method}] #{args}" if @verbose
  end
  
end
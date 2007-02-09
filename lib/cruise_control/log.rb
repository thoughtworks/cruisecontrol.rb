module CruiseControl

  class Log
  
    def self.verbose=(verbose)
      @verbose = verbose
    end
    
    def self.verbose?
      @verbose or false
    end
  
    def self.event(description, severity = :info)
      return if severity == :debug and not @verbose
      message = "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{description}"
      Log.send(severity.to_sym, message)
    end
  
    def self.method_missing(method, *args, &block)
      return if method == :debug and not @verbose
      first_arg = args.shift
      message = backtrace = nil
      case first_arg
      when Exception
        message = "#{print_severity(method)} #{first_arg.message}"
        backtrace = first_arg.backtrace.map { |line| "#{print_severity(method)}   #{line}" }
      else
        message = "#{print_severity(method)} #{first_arg}"
      end
      RAILS_DEFAULT_LOGGER.send(method, message, *args, &block)
      backtrace.each { |line| RAILS_DEFAULT_LOGGER.send(method, line) } if backtrace
      is_error = (method == :error or method == :fatal)
      if @verbose or is_error and defined?(RAILS_ENV) and RAILS_ENV != 'test'  
        stream = is_error ? STDERR : STDOUT
        stream.puts message
        backtrace.each { |line| stream.puts line } if backtrace and @verbose
      end
    end
    
    # nicely aligned printout of message severity
    def self.print_severity(severity)
      severity = severity.to_s
      '[' + severity + ']' + ' ' * (5 - severity.length)
    end
    
  end
  
end
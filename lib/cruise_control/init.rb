module CruiseControl
  class Init
  
    def run
      command = ARGV.shift
      if command.nil?
        STDERR.puts "Type 'cruise --help' for usage."
        exit -1
      elsif method = method_for_command(command)
        self.send(method)
      else
        STDERR.puts "Unknown command : '#{command}'"
        STDERR.puts "Type 'cruise --help' for usage."
        exit -1
      end
    end
    
    def method_for_command(command)
      case command
      when 'start'                            then :start
      when 'stop'                             then :stop
      when 'add'                              then :add
      when 'build', 'builder'                 then :builder
      when 'version', '-v', '--version'       then :version
      when 'help', '-h', '--help', '/?', '-?' then :help
      end
    end
  
    def start
      require File.join(File.dirname(__FILE__), '..', 'platform')
      Platform.running_as_daemon = ARGV.include?('-d') || ARGV.include?('--daemon')
      load File.join(File.dirname(__FILE__), '..', '..', 'script', 'server')
    end

    def stop
      pid_file = File.join("tmp", "pids", "mongrel.pid")
      if File.exist?(pid_file)
        exec "mongrel_rails stop -P #{pid_file}"
      end
    end

    def add
      load File.join(File.dirname(__FILE__), '..', '..', 'script', 'add_project')
    end

    def builder
      load File.join(File.dirname(__FILE__), '..', '..', 'script', 'builder')
    end
  
    def version
      puts <<-EOL
    CruiseControl.rb, version #{CruiseControl::VERSION::STRING}
    Copyright (C) 2007 ThoughtWorks
      EOL
    end
  
    def help
      command = ARGV.shift

      ARGV.clear << '--help'
      if command.nil?
        puts <<-EOL
    Usage: cruise <command> [options] [args]

    CruiseControl.rb command-line client, version #{CruiseControl::VERSION::STRING}
    Type 'cruise help <command>' for help on a specific command.
    Type 'cruise --version' to see the version number.

    Available commands:
      start      - starts the web server
      add        - adds a project
      build      - starts the builder for an individual project

    CruiseControl.rb is a Continous Integration Server.
    For additional information, see http://cruisecontrolrb.rubyforge.org/
        EOL
      elsif method_for_command(command)
        self.send(method_for_command(command))
      else
        STDERR.puts "Type 'cruise help' for usage."
        exit -1
      end

    end
  
  end
end
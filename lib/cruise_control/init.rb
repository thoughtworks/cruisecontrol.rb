module CruiseControl
  class Init
    DEFAULT_PORT = 3333
    DEFAULT_ENV  = 'production'
  
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
      require ENV_PATH

      unless ARGV.include?('-p') || ARGV.include?('--port')
        ARGV << '-p'
        ARGV << DEFAULT_PORT.to_s
      end
      
      unless ARGV.include?('-e') || ARGV.include?('--environment')
        ARGV << '-e'
        ARGV << 'production'
      end

      unless ARGV.include?('-c') || ARGV.include?('--config')
        ARGV << '-c'
        ARGV << Rails.root.join('config.ru').to_s
      end

      unless ARGV.include?('-P') || ARGV.include?('--pid')
        ARGV << '-P'
        ARGV << Rails.root.join('tmp', 'pids', 'server.pid').to_s
      end
      
      require File.join(File.dirname(__FILE__), '..', 'platform')
      Platform.running_as_daemon = ARGV.include?('-d') || ARGV.include?('--daemon')
      require 'rails/commands/server'
      
      Rails::Server.new.tap { |server|
        Dir.chdir(Rails.application.root)
        server.start
      }
    end

    def stop
      require ENV_PATH

      stop_builders
      stop_server
    end

    def stop_server
      pid_file = Rails.root.join("tmp", "pids", "server.pid")

      if pid_file.exist?
        exec "kill -KILL #{pid_file.read.chomp}"
        pid_file.delete
      end
    end

    def stop_builders
      Rails.root.join("tmp", "pids", "builders").children.each do |pid_file|
        Platform.kill_child_process(pid_file.read.chomp)
      end
    end

    def add
      require ENV_PATH
      load File.join(File.dirname(__FILE__), '..', '..', 'script', 'add_project')
    end

    def builder
      load File.join(File.dirname(__FILE__), '..', '..', 'script', 'builder')
    end
  
    def version
      puts <<-EOL
    CruiseControl.rb, version #{CruiseControl::VERSION::STRING}
    Copyright (C) 2011 ThoughtWorks
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
  start      - starts the web server (port 3333, production environment by default)
  stop       - stops the web server
  add        - adds a project
  build      - starts the builder for an individual project

CruiseControl.rb is a Continous Integration Server.
For additional information, see http://cruisecontrolrb.thoughtworks.com/
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
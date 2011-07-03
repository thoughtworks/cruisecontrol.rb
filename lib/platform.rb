require 'rbconfig'

module Platform

  def running_as_daemon?
    @running_as_daemon
  end
  module_function :running_as_daemon?

  def running_as_daemon=(value)
    @running_as_daemon = value
  end
  module_function :running_as_daemon=

  def family
    target_os = Config::CONFIG["target_os"] or raise 'Cannot determine operating system'
    case target_os
    when /linux/i then 'linux'
    when /32/ then 'mswin32'
    when /darwin/ then 'powerpc-darwin'
    when /cyg/ then 'cygwin'
    when /solaris/ then 'solaris'
    when /(free|open|net)bsd/ then 'bsd'
    else raise "Unknown OS: #{target_os}"
    end
  end
  module_function :family

  def user
    family == "mswin32" ? ENV['USERNAME'] : ENV['USER']
  end
  module_function :user

  def prompt(dir=Dir.pwd)
    prompt = "#{dir.gsub(/\//, File::SEPARATOR)} #{user}$"
  end
  module_function :prompt

  def interpreter
    return File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name']) unless defined?(JRUBY_VERSION)
    "#{Rails.root}/script/jruby"
  end
  module_function :interpreter

  def gem_cmd
    "#{Platform.interpreter} -S gem"
  end
  module_function :gem_cmd

  def bundle_cmd
    "#{Platform.interpreter} -S bundle"
  end
  module_function :bundle_cmd

  def create_child_process(project_name, command)
    Bundler.with_clean_env do
      if Kernel.respond_to?(:fork)
        begin
          pid = fork || safely_exec(command)

          # safely exec
          Process.detach(pid)
        rescue NotImplementedError   # Kernel.fork exists but not implemented in Windows
          Thread.new { system(command) }
        end
      else
        Thread.new { system(command) }
      end
    end
  end
  module_function :create_child_process

  def project_pid_file(project_name)
    Rails.root.join('tmp', 'pids', 'builders', "#{project_name}.pid")
  end
  module_function :project_pid_file

  def kill_project_builder(project_name)
    kill_child_process project_pid_file(project_name).read.chomp
  end
  module_function :kill_project_builder

  def kill_child_process(pid)
    kill_tree = Rails.root.join('script', 'killtree')
    Kernel.system("#{kill_tree} #{pid}")
  end
  module_function :kill_child_process

  def safely_exec(command)
    if running_as_daemon?
      STDIN.reopen("/dev/null")
      STDOUT.reopen("/dev/null", "w")
      STDERR.reopen("/dev/null", "w")
    end
    exec command
  end
  module_function :safely_exec

end

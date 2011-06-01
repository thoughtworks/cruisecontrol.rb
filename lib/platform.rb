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
    "jruby"
  end
  module_function :interpreter

  def gem_cmd
    "#{Platform.interpreter} -S gem"
  end
  module_function :gem_cmd

  def bundle_cmd
    @bundle_cmd ||= begin
      gem_which_bundler = `#{Platform.gem_cmd} which bundler`.strip
      bundler_root = File.expand_path(File.join(File.dirname(gem_which_bundler), ".."))
      File.join(bundler_root, "bin", "bundle")
    end
  end
  module_function :bundle_cmd

  def create_child_process(project_name, command)
    Bundler.with_clean_env do
      if Kernel.respond_to?(:fork)
        begin
          pid = fork || safely_exec(command)

          # safely exec
          Process.detach(pid)
          pid_file = Rails.root.join('tmp', 'pids', 'builders', "#{project_name}.pid")
          FileUtils.mkdir_p(File.dirname(pid_file))
          File.open(pid_file, "w") {|f| f.write pid }
        rescue NotImplementedError   # Kernel.fork exists but not implemented in Windows
          Thread.new { system(command) }
        end
      else
        Thread.new { system(command) }
      end
    end
  end
  module_function :create_child_process

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

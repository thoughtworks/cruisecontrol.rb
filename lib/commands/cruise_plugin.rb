# Cruise Plugin Manager (modified from the Rails Plugin Manager).
# 
# Listing available plugins:
#
#   $ ./script/plugin list
#   continuous_builder            http://dev.rubyonrails.com/svn/rails/plugins/continuous_builder
#   asset_timestamping            http://svn.aviditybytes.com/rails/plugins/asset_timestamping
#   enumerations_mixin            http://svn.protocool.com/rails/plugins/enumerations_mixin/trunk
#   calculations                  http://techno-weenie.net/svn/projects/calculations/
#   ...
#
# Installing plugins:
#
#   $ ./script/plugin install continuous_builder asset_timestamping
#
# Finding Repositories:
#
#   $ ./script/plugin discover
# 
# Adding Repositories:
#
#   $ ./script/plugin source http://svn.protocool.com/rails/plugins/
#
# How it works:
# 
#   * Maintains a list of subversion repositories that are assumed to have
#     a plugin directory structure. Manage them with the (source, unsource,
#     and sources commands)
#     
#   * The discover command scrapes the following page for things that
#     look like subversion repositories with plugins:
#     http://cruisecontrolrb.thoughtworks.com/documentation/plugin_repositories
# 
#   * Unless you specify that you want to use svn, script/plugin uses plain old
#     HTTP for downloads.  The following bullets are true if you specify
#     that you want to use svn.
#
# This is Free Software, copyright 2005 by Ryan Tomayko (rtomayko@gmail.com) 
# and is licensed MIT: (http://www.opensource.org/licenses/mit-license.php)

$verbose = false
PLUGINS_ROOT = CRUISE_DATA_ROOT + "/builder_plugins"

require 'open-uri'
require 'fileutils'
require 'tempfile'

include FileUtils

class RailsEnvironment
  attr_reader :root, :plugins_root

  def initialize(dir)
    @root = dir
    @plugins_root = PLUGINS_ROOT
  end

  def self.find(dir=nil)
    dir ||= pwd
    while dir.length > 1
      return new(dir) if File.exist?(File.join(dir, 'config', 'environment.rb'))
      dir = File.dirname(dir)
    end
  end
  
  def self.default
    @default ||= find
  end
  
  def self.default=(rails_env)
    @default = rails_env
  end
  
  def install(name_uri_or_plugin)
    if name_uri_or_plugin.is_a? String
      if name_uri_or_plugin =~ /:\/\// 
        plugin = Plugin.new(name_uri_or_plugin)
      else
        plugin = Plugins[name_uri_or_plugin]
      end
    else
      plugin = name_uri_or_plugin
    end
    unless plugin.nil?
      plugin.install
    else
      puts "Plugin not found: #{name_uri_or_plugin}"
    end
  end
 
  def use_svn?
    require 'active_support/core_ext/kernel'
    silence_stderr {`svn --version` rescue nil}
    !$?.nil? && $?.success?
  end

  def use_checkout?
    # this is a bit of a guess. we assume that if the rails environment
    # is under subversion then they probably want the plugin checked out
    # instead of exported. This can be overridden on the command line
    File.directory?("#{root}/.svn")
  end

  def best_install_method
    return :http unless use_svn?
    case
      when use_checkout? then :checkout
      else :export
    end
  end
end

class Plugin
  attr_reader :name, :uri
  
  def initialize(uri, name=nil)
    @uri = uri
    guess_name(uri)
  end
  
  def self.find(name)
    name =~ /\// ? new(name) : Repositories.instance.find_plugin(name)
  end
  
  def to_s
    "#{@name.ljust(30)}#{@uri}"
  end
  
  def svn_url?
    @uri =~ /svn(?:\+ssh)?:\/\/*/
  end
  
  def installed?
    File.directory?("#{rails_env.plugins_root}/#{name}")
  end
  
  def install(method=nil, options = {})
    method ||= rails_env.best_install_method?
    method   = :export if method == :http and svn_url?

    uninstall if installed? and options[:force]

    unless installed?
      send("install_using_#{method}", options)
      run_install_hook
    else
      puts "already installed: #{name} (#{uri}).  pass --force to reinstall"
    end
  end

  def uninstall
    path = "#{rails_env.plugins_root}/#{name}"
    if File.directory?(path)
      puts "Removing '#{path}'" if $verbose
      run_uninstall_hook
      rm_r path
    else
      puts "Plugin doesn't exist: #{path}"
    end
  end

  def info
    tmp = "#{rails_env.root}/_tmp_readme"
    if svn_url?
      cmd = "svn export #{@uri} \"#{rails_env.root}/#{tmp}\""
      puts cmd if $verbose
      system(cmd)
    end
    open(svn_url? ? tmp : File.join(@uri, 'README')) do |stream|
      stream.read
    end rescue "No README found in #{uri}"
  ensure
    FileUtils.rm_rf tmp if svn_url?
  end

  private 

    def run_install_hook
      install_hook_file = "#{rails_env.plugins_root}/#{name}/install.rb"
      load install_hook_file if File.exists? install_hook_file
    end

    def run_uninstall_hook
      uninstall_hook_file = "#{rails_env.plugins_root}/#{name}/uninstall.rb"
      load uninstall_hook_file if File.exists? uninstall_hook_file
    end

    def install_using_export(options = {})
      svn_command :export, options
    end
    
    def install_using_checkout(options = {})
      svn_command :checkout, options
    end
    
    def install_using_http(options = {})
      root = rails_env.plugins_root
      mkdir_p "#{root}/#{@name}"
      Dir.chdir "#{root}/#{@name}" do
        puts "fetching from '#{uri}'" if $verbose
        fetcher = RecursiveHTTPFetcher.new(uri, -1)
        fetcher.quiet = true if options[:quiet]
        fetcher.fetch
      end
    end

    def svn_command(cmd, options = {})
      root = rails_env.plugins_root
      mkdir_p "#{root}"
      base_cmd = "svn #{cmd} #{uri} \"#{root}/#{name}\""
      base_cmd += ' -q' if options[:quiet] and not $verbose
      base_cmd += " -r #{options[:revision]}" if options[:revision]
      puts base_cmd if $verbose
      system(base_cmd)
    end

    def guess_name(url)
      @name = File.basename(url)
      if @name == 'trunk' || @name.empty?
        @name = File.basename(File.dirname(url))
      end
    end
    
    def rails_env
      @rails_env || RailsEnvironment.default
    end
end

class Repositories
  include Enumerable
  
  def initialize(cache_file = File.join(CRUISE_DATA_ROOT, "plugin_repositories.txt"))
    @cache_file = File.expand_path(cache_file)
    load!
  end
  
  def each(&block)
    @repositories.each(&block)
  end
  
  def add(uri)
    unless find{|repo| repo.uri == uri }
      @repositories.push(Repository.new(uri)).last
    end
  end
  
  def remove(uri)
    @repositories.reject!{|repo| repo.uri == uri}
  end
  
  def exist?(uri)
    @repositories.detect{|repo| repo.uri == uri }
  end
  
  def all
    @repositories
  end
  
  def find_plugin(name)
    @repositories.each do |repo|
      repo.each do |plugin|
        return plugin if plugin.name == name
      end
    end
    return nil
  end
  
  def load!
    contents = File.exist?(@cache_file) ? File.read(@cache_file) : defaults
    contents = defaults if contents.empty?
    @repositories = contents.split(/\n/).reject do |line|
      line =~ /^\s*#/ or line =~ /^\s*$/
    end.map { |source| Repository.new(source.strip) }
  end
  
  def save
    File.open(@cache_file, 'w') do |f|
      each do |repo|
        f.write(repo.uri)
        f.write("\n")
      end
    end
  end
  
  def defaults
    <<-DEFAULTS
    http://ccrb-contrib.rubyforge.org/svn/plugins/
    DEFAULTS
  end
 
  def find_home
    ['HOME', 'USERPROFILE'].each do |homekey|
      return ENV[homekey] if ENV[homekey]
    end
    if ENV['HOMEDRIVE'] && ENV['HOMEPATH']
      return "#{ENV['HOMEDRIVE']}:#{ENV['HOMEPATH']}"
    end
    begin
      File.expand_path("~")
    rescue StandardError => ex
      if File::ALT_SEPARATOR
        "C:/"
      else
        "/"
      end
    end
  end

  def self.instance
    @instance ||= Repositories.new
  end
  
  def self.each(&block)
    self.instance.each(&block)
  end
end

class Repository
  include Enumerable
  attr_reader :uri, :plugins
  
  def initialize(uri)
    @uri = uri.chomp('/') << "/"
    @plugins = nil
  end
  
  def plugins
    unless @plugins
      if $verbose
        puts "Discovering plugins in #{@uri}" 
        # puts index
      end

      @plugins = index.reject{ |line| line !~ /\/$/ }
      @plugins.map! { |name| Plugin.new(File.join(@uri, name), name) }
    end

    @plugins
  end
  
  def each(&block)
    plugins.each(&block)
  end
  
  private
    def index
      @index ||= RecursiveHTTPFetcher.new(@uri).ls
    end
end


# load default environment and parse arguments
require 'optparse'
module Commands

  class Plugin
    attr_reader :environment, :script_name, :sources
    def initialize
      @environment = RailsEnvironment.default
      @rails_root = RailsEnvironment.default.root
      @script_name = File.basename($0) 
      @sources = []
    end
    
    def environment=(value)
      @environment = value
      RailsEnvironment.default = value
    end
    
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@script_name} [OPTIONS] command"
        o.define_head "Rails plugin manager."
        
        o.separator ""        
        o.separator "GENERAL OPTIONS"
        
        o.on("-r", "--root=DIR", String,
             "Set an explicit rails app directory.",
             "Default: #{@rails_root}") { |@rails_root| self.environment = RailsEnvironment.new(@rails_root) }
        o.on("-s", "--source=URL1,URL2", Array,
             "Use the specified plugin repositories instead of the defaults.") { |@sources|}
        
        o.on("-v", "--verbose", "Turn on verbose output.") { |$verbose| }
        o.on("-h", "--help", "Show this help message.") { puts o; exit }
        
        o.separator "
COMMANDS

  discover   Discover plugin repositories.
  list       List available plugins.
  install    Install plugin(s) from known repositories or URLs.
  update     Update installed plugins.
  remove     Uninstall plugins.
  source     Add a plugin source repository.
  unsource   Remove a plugin repository.
  sources    List currently configured plugin repositories.

EXAMPLES
  Install a plugin:
    #{@script_name} install growl_notifier
  Install a plugin from a subversion URL:
    #{@script_name} install http://ccrb-contrib.rubyforge.org/svn/plugins/growl_notifier/
  List all available plugins:
    #{@script_name} list
  List plugins in the specified repository:
    #{@script_name} list --source=http://ccrb-contrib.rubyforge.org/svn/plugins/
  Discover and prompt to add new repositories:
    #{@script_name} discover
  Discover new repositories but just list them, don't add anything:
    #{@script_name} discover -l
  Add a new repository to the source list:
    #{@script_name} source http://ccrb-contrib.rubyforge.org/svn/plugins/
  Remove a repository from the source list:
    #{@script_name} unsource http://ccrb-contrib.rubyforge.org/svn/plugins/
  Show currently configured repositories:
    #{@script_name} sources"
    
      end
    end
    
    def parse!(args=ARGV)
      general, sub = split_args(args)
      options.parse!(general)
      
      command = general.shift
      if command =~ /^(list|discover|install|source|unsource|sources|remove|update|info)$/
        command = Commands.const_get(command.capitalize).new(self)
        command.parse!(sub)
      else
        puts "Unknown command: #{command}"
        puts options
        exit 1
      end
    end
    
    def split_args(args)
      left = []
      left << args.shift while args[0] and args[0] =~ /^-/
      left << args.shift if args[0]
      return [left, args]
    end
    
    def self.parse!(args=ARGV)
      Plugin.new.parse!(args)
    end
  end
  
  
  class List
    def initialize(base_command)
      @base_command = base_command
      @sources = []
      @local = false
      @remote = true
    end
    
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} list [OPTIONS] [PATTERN]"
        o.define_head "List available plugins."
        o.separator   ""        
        o.separator   "Options:"
        o.separator   ""
        o.on(         "-s", "--source=URL1,URL2", Array,
                      "Use the specified plugin repositories.") {|@sources|}
        o.on(         "--local", 
                      "List locally installed plugins.") {|@local| @remote = false}
        o.on(         "--remote",
                      "List remotely available plugins. This is the default behavior",
                      "unless --local is provided.") {|@remote|}
      end
    end
    
    def parse!(args)
      options.order!(args)
      unless @sources.empty?
        @sources.map!{ |uri| Repository.new(uri) }
      else
        @sources = Repositories.instance.all
      end
      if @remote
        @sources.map{|r| r.plugins}.flatten.each do |plugin| 
          if @local or !plugin.installed?
            puts plugin.to_s
          end
        end
      else
        cd CRUISE_DATA_ROOT + "/builder_plugins"
        Dir["*"].select{|p| File.directory?(p)}.each do |name| 
          puts name
        end
      end
    end
  end
  
  
  class Sources
    def initialize(base_command)
      @base_command = base_command
    end
    
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} sources [OPTIONS] [PATTERN]"
        o.define_head "List configured plugin repositories."
        o.separator   ""        
        o.separator   "Options:"
        o.separator   ""
        o.on(         "-c", "--check", 
                      "Report status of repository.") { |@sources|}
      end
    end
    
    def parse!(args)
      options.parse!(args)
      Repositories.each do |repo|
        puts repo.uri
      end
    end
  end
  
  
  class Source
    def initialize(base_command)
      @base_command = base_command
    end
    
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} source REPOSITORY [REPOSITORY [REPOSITORY]...]"
        o.define_head "Add new repositories to the default search list."
      end
    end
    
    def parse!(args)
      options.parse!(args)
      count = 0
      args.each do |uri|
        if Repositories.instance.add(uri)
          puts "added: #{uri.ljust(50)}" if $verbose
          count += 1
        else
          puts "failed: #{uri.ljust(50)}"
        end
      end
      Repositories.instance.save
      puts "Added #{count} repositories."
    end
  end
  
  
  class Unsource
    def initialize(base_command)
      @base_command = base_command
    end
    
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} source URI [URI [URI]...]"
        o.define_head "Remove repositories from the default search list."
        o.separator ""
        o.on_tail("-h", "--help", "Show this help message.") { puts o; exit }
      end
    end
    
    def parse!(args)
      options.parse!(args)
      count = 0
      args.each do |uri|
        if Repositories.instance.remove(uri)
          count += 1
          puts "removed: #{uri.ljust(50)}"
        else
          puts "failed: #{uri.ljust(50)}"
        end
      end
      Repositories.instance.save
      puts "Removed #{count} repositories."
    end
  end

  
  class Discover
    def initialize(base_command)
      @base_command = base_command
      @list = false
      @prompt = true
    end
    
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} discover URI [URI [URI]...]"
        o.define_head "Discover repositories referenced on a page."
        o.separator   ""        
        o.separator   "Options:"
        o.separator   ""
        o.on(         "-l", "--list", 
                      "List but don't prompt or add discovered repositories.") { |@list| @prompt = !@list }
        o.on(         "-n", "--no-prompt", 
                      "Add all new repositories without prompting.") { |v| @prompt = !v }
      end
    end

    def parse!(args)
      options.parse!(args)
      args = ['http://localhost:3333/documentation/plugin_repositories'] if args.empty?
      # args = ['http://cruisecontrolrb.thoughtworks.com/documentation/plugin_repositories'] if args.empty?
      args.each do |uri|
        scrape(uri) do |repo_uri|
          unless Repositories.instance.exist?(repo_uri)
            catch(:next_uri) do
              if @prompt
                begin
                  $stdout.print "Add #{repo_uri}? [Y/n] "
                  throw :next_uri if $stdin.gets !~ /^y?$/i
                rescue Interrupt
                  $stdout.puts
                  exit 1
                end
              elsif @list
                puts repo_uri
                throw :next_uri
              end
              Repositories.instance.add(repo_uri)
              puts "discovered: #{repo_uri}" if $verbose or !@prompt
            end
          end
        end
      end
      Repositories.instance.save
    end
    
    def scrape(uri)
      require 'open-uri'
      puts "Scraping #{uri}" if $verbose
      dupes = []
      content = open(uri).each do |line|
        begin
          if line =~ /<a[^>]*href=['"]([^'"]*)['"]/ || line =~ /(svn:\/\/[^<|\n]*)/
            uri = $1
            if uri =~ /^\w+:\/\//
              yield uri unless dupes.include?(uri) || Repositories.instance.exist?(uri)
              dupes << uri
            end
          end
        rescue
          puts "Problems scraping '#{uri}': #{$!.to_s}"
        end
      end
    end
  end
  
  class Install
    def initialize(base_command)
      @base_command = base_command
      @method = :http
      @options = { :quiet => false, :revision => nil, :force => false }
    end
    
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} install PLUGIN [PLUGIN [PLUGIN] ...]"
        o.define_head "Install one or more plugins."
        o.separator   ""
        o.separator   "Options:"
        o.on(         "-o", "--checkout",
                      "Use svn checkout to grab the plugin.",
                      "Enables updating but does not add a svn:externals entry.") { |v| @method = :checkout }
        o.on(         "-q", "--quiet",
                      "Suppresses the output from installation.",
                      "Ignored if -v is passed (./script/plugin -v install ...)") { |v| @options[:quiet] = true }
        o.on(         "-r REVISION", "--revision REVISION",
                      "Checks out the given revision from subversion.",
                      "Ignored if subversion is not used.") { |v| @options[:revision] = v }
        o.on(         "-f", "--force",
                      "Reinstalls a plugin if it's already installed.") { |v| @options[:force] = true }
        o.separator   ""
        o.separator   "You can specify plugin names as given in 'plugin list' output or absolute URLs to "
        o.separator   "a plugin repository."
      end
    end
    
    def determine_install_method
      best = @base_command.environment.best_install_method
      @method = :http if best == :http and @method == :export
      case
      when (best == :http and @method != :http)
        msg = "Cannot install using subversion because `svn' cannot be found in your PATH"
      when (best == :export and (@method != :export and @method != :http))
        msg = "Cannot install using #{@method} because this project is not under subversion."
      end
      if msg
        puts msg
        exit 1
      end
      @method
    end
    
    def parse!(args)
      options.parse!(args)
      environment = @base_command.environment
      install_method = determine_install_method
      puts "Plugins will be installed using #{install_method}" if $verbose
      args.each do |name|
        ::Plugin.find(name).install(install_method, @options)
      end
    rescue StandardError => e
      puts "Plugin not found: #{args.inspect}"
      puts e.inspect if $verbose
      exit 1
    end
  end

  class Update
    def initialize(base_command)
      @base_command = base_command
    end
   
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} update [name [name]...]"
        o.on(         "-r REVISION", "--revision REVISION",
                      "Checks out the given revision from subversion.",
                      "Ignored if subversion is not used.") { |v| @revision = v }
        o.define_head "Update plugins."
      end
    end
   
    def parse!(args)
      options.parse!(args)
      root = @base_command.environment.root
      cd root
      args = Dir["#{PLUGINS_ROOT}/*"].map do |f|
        File.directory?("#{f}/.svn") ? File.basename(f) : nil
      end.compact if args.empty?
      cd PLUGINS_ROOT
      args.each do |name|
        if File.directory?(name)
          puts "Updating plugin: #{name}"
          system("svn #{$verbose ? '' : '-q'} up \"#{name}\" #{@revision ? "-r #{@revision}" : ''}")
        else
          puts "Plugin doesn't exist: #{name}"
        end
      end
    end
  end

  class Remove
    def initialize(base_command)
      @base_command = base_command
    end
    
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} remove name [name]..."
        o.define_head "Remove plugins."
      end
    end
    
    def parse!(args)
      options.parse!(args)
      root = @base_command.environment.root
      args.each do |name|
        ::Plugin.new(name).uninstall
      end
    end
  end

  class Info
    def initialize(base_command)
      @base_command = base_command
    end

    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: #{@base_command.script_name} info name [name]..."
        o.define_head "Shows plugin info at {url}/about.yml."
      end
    end

    def parse!(args)
      options.parse!(args)
      args.each do |name|
        puts ::Plugin.find(name).info
        puts
      end
    end
  end
end
 
class RecursiveHTTPFetcher
  attr_accessor :quiet
  def initialize(urls_to_fetch, level = 1, cwd = ".")
    @level = level
    @cwd = cwd
    @urls_to_fetch = urls_to_fetch.to_a
    @quiet = false
  end

  def ls
    @urls_to_fetch.collect do |url|
      if url =~ /^svn:\/\/.*/
        `svn ls #{url}`.split("\n").map {|entry| "/#{entry}"} rescue nil
      else
        open(url) do |stream|
          links("", stream.read)
        end rescue nil
      end
    end.flatten
  end

  def push_d(dir)
    @cwd = File.join(@cwd, dir)
    FileUtils.mkdir_p(@cwd)
  end

  def pop_d
    @cwd = File.dirname(@cwd)
  end

  def links(base_url, contents)
    links = []
    contents.scan(/href\s*=\s*\"*[^\">]*/i) do |link|
      link = link.sub(/href="/i, "")
      next if link =~ /svnindex.xsl$/
      next if link =~ /^(\w*:|)\/\// || link =~ /^\./
      links << File.join(base_url, link)
    end
    links
  end
  
  def download(link)
    puts "+ #{File.join(@cwd, File.basename(link))}" unless @quiet
    open(link) do |stream|
      File.open(File.join(@cwd, File.basename(link)), "wb") do |file|
        file.write(stream.read)
      end
    end
  end
  
  def fetch(links = @urls_to_fetch)
    links.each do |l|
      (l =~ /\/$/ || links == @urls_to_fetch) ? fetch_dir(l) : download(l)
    end
  end
  
  def fetch_dir(url)
    @level += 1
    push_d(File.basename(url)) if @level > 0
    open(url) do |stream|
      contents =  stream.read
      fetch(links(url, contents))
    end
    pop_d if @level > 0
    @level -= 1
  end
end


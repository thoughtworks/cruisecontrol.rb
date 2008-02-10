class Subversion
end

require 'builder_error'
require 'subversion/changeset_log_parser'
require 'subversion/info_parser'
require 'subversion/log_parser'
require 'subversion/propget_parser'
require 'subversion/update_parser'

class Subversion
  include CommandLine

  attr_accessor :url, :path, :username, :password, :check_externals

  def initialize(options = {})
    @url = options.delete(:url)
    @path = options.delete(:path) || "."
    @username = options.delete(:username)
    @password = options.delete(:password)
    @interactive = options.delete(:interactive)
    @error_log = options.delete(:error_log)
    @check_externals = options.has_key?(:check_externals) ? options.delete(:check_externals) : true
    
    raise "don't know how to handle '#{options.keys.first}'" if options.length > 0
  end
  
  def error_log
    @error_log ? @error_log : File.join(@path, "..", "svn.err")
  end
  
  def clean_checkout(revision = nil, stdout = $stdout)
    FileUtils.rm_rf(path)
    checkout(revision, stdout)
  end

  def checkout(revision = nil, stdout = $stdout)
    @url or raise 'URL not specified'

    options = [@url, path]
    options << "--username" << @username if @username
    options << "--password" << @password if @password
    options << "--revision" << revision_number(revision) if revision

    # need to read from command output, because otherwise tests break
    svn('co', options) do |io| 
      begin
        while line = io.gets
          stdout.puts line
        end
      rescue EOFError
      end
    end
  end

  def last_locally_known_revision
    return Revision.new(0) unless File.exist?(path)
    Revision.new(info.last_changed_revision)
  end

  def latest_revision
    svn_output = log "HEAD", "1", ['--limit', '1']
    Subversion::LogParser.new.parse(svn_output).first
  end
  
  def up_to_date?(reasons = [], revision_number = last_locally_known_revision.number)
    result = true
    
    latest_revision = self.latest_revision()
    if latest_revision != Revision.new(revision_number)
      reasons << "New revision #{latest_revision.number} detected"
      reasons << revisions_since(revision_number)
      result = false
    end
    
    if @check_externals
      externals.each do |ext_path, ext_url|
        ext_logger = ExternalReasons.new(ext_path, reasons)
        ext_svn = Subversion.new(:path => File.join(self.path, ext_path), :url => ext_url)
        result = false unless ext_svn.up_to_date?(ext_logger)
      end
    end
    
    return result
  end

  def update(revision = nil)
    revision_number = revision ? revision_number(revision) : 'HEAD'
    svn_output = svn('update', ["--revision", revision_number])
    Subversion::UpdateParser.new.parse(svn_output)
  end

  def externals
    return {} unless File.exist?(path)
    
    svn_output = svn('propget', ['-R', 'svn:externals'])
    Subversion::PropgetParser.new.parse(svn_output)
  end
  
  private
  
  def revisions_since(revision_number)
    svn_output = log('HEAD', revision_number)
    log_parser = Subversion::LogParser.new
    log_parser.parse(svn_output)
  end

  def log(from, to, arguments = [])
    svn('log', arguments + ["--revision", "#{from}:#{to}", '--verbose', '--xml', url], :execute_locally => url.blank?)
  end
  
  def info
    svn_output = svn('info', ["--xml"])
    Subversion::InfoParser.new.parse(svn_output)
  end

  def svn(operation, arguments, options = {}, &block)
    command = ["svn"]
    command << "--non-interactive" unless @interactive
    command << operation
    command += arguments.compact
    command
    
    execute_in_local_copy(command, options, &block)
  end

  def revision_number(revision)
    revision.respond_to?(:number) ? revision.number : revision.to_i
  end

  def execute_in_local_copy(command, options, &block)
    if block_given?
      execute(command, &block)
    else
      error_log = File.expand_path(self.error_log)
      if options[:execute_locally] != false
        Dir.chdir(path) do
          execute_with_error_log(command, error_log)
        end
      else
        execute_with_error_log(command, error_log)
      end
    end
  end
  
  def execute_with_error_log(command, error_log)
    FileUtils.rm_f(error_log)
    FileUtils.touch(error_log)
    execute(command, :stderr => error_log) do |io| 
      result = io.readlines 
      begin 
        error_message = File.open(error_log){|f|f.read}.strip.split("\n")[1] || ""
      rescue
        error_message = ""
      ensure
        FileUtils.rm_f(error_log)
      end
      raise BuilderError.new(error_message, "svn_error") unless error_message.empty?
      return result
    end
  end
  
  Info = Struct.new :revision, :last_changed_revision, :last_changed_author
  
  class ExternalReasons < Struct.new :external, :reasons
    def <<(reason)
      if reason.is_a? String
        reasons << "#{reason} in external '#{external}'"
      else
        reasons << reason
      end
      self
    end
  end
end

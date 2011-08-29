module SourceControl

  class Subversion < AbstractAdapter
  end

  require 'builder_error'
  require 'source_control/subversion/changeset_log_parser'
  require 'source_control/subversion/info_parser'
  require 'source_control/subversion/log_parser'
  require 'source_control/subversion/propget_parser'
  require 'source_control/subversion/update_parser'

  class Subversion < AbstractAdapter

    attr_accessor :username, :password, :check_externals

    def initialize(options = {})
      options = options.dup
      @path = options.delete(:path) || "."
      @error_log = options.delete(:error_log)
      @repository = options.delete(:repository)
      @username = options.delete(:username)
      @password = options.delete(:password)
      @interactive = options.delete(:interactive)
      @check_externals = options.has_key?(:check_externals) ? options.delete(:check_externals) : true

      if options[:branch]
        raise "Subversion doesn't accept --branch property. You should specify Subversion URL for the branch in the --repository option."
      end

      raise "don't know how to handle '#{options.keys.first}'" if options.length > 0
    end

    def checkout(revision = nil, stdout = $stdout, checkout_path = path)
      raise 'Repository location is not specified' unless repository

      arguments = [repository, checkout_path]
      arguments << "--username" << @username if @username
      arguments << "--password" << @password if @password
      arguments << "--revision" << revision_number(revision) if revision

      # need to read from command output, because otherwise tests break
      svn('co', arguments, :execute_in_project_directory => false) do |io|
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
      Revision.new(info.revision)
    end

    def latest_revision
      svn_output = log "HEAD", "1", ['--limit', '1']
      Subversion::LogParser.new.parse(svn_output).first
    end

    def up_to_date?(reasons = [], revision_number = last_locally_known_revision.number)
      result = true

      latest_revision = self.latest_revision
      if latest_revision > Revision.new(revision_number)
        reasons << "New revision #{latest_revision.number} detected"
        reasons.concat(revisions_since(revision_number))
        result = false
      end

      if @check_externals
        externals.each do |ext_path, ext_url|
          ext_logger = ExternalReasons.new(ext_path, reasons)
          ext_svn = Subversion.new(:path => File.join(self.path, ext_path),
                                   :repository => ext_url,
                                   :check_externals => false)
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

    def creates_ordered_build_labels?() true end

    def repository
      # Try to detect repository location if not provided
      @repository || info.url
    end

    attr_writer :repository
    
    private

    def revisions_since(revision_number)
      svn_output = log('HEAD', revision_number)
      log_parser = Subversion::LogParser.new
      revisions = log_parser.parse(svn_output)
      revisions.reject {|revision| revision.number == revision_number} # cut out the revision that was asked for
    end

    def log(from, to, arguments = [])
      svn('log', arguments + ["--revision", "#{from}:#{to}", '--verbose', '--xml', @repository],
          :execute_in_project_directory => @repository.blank?)
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

    Info = Struct.new :revision, :last_changed_revision, :last_changed_author, :url

    class ExternalReasons < Struct.new :external, :reasons
      delegate :concat, :to => :reasons

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

end

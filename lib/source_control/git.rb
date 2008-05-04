module SourceControl

  class Git < AbstractAdapter

    attr_accessor :repository

    def initialize(options)
      options = options.dup
      @path = options.delete(:path) || "."
      @error_log = options.delete(:error_log)
      @interactive = options.delete(:interactive)
      @repository = options.delete(:repository)
      raise "don't know how to handle '#{options.keys.first}'" if options.length > 0
    end

    def checkout(stdout = $stdout)
      raise 'Repository location is not specified' unless @repository

# TODO: which of these do we need for Git?
#      options = []
#      options << "--username" << @username if @username
#      options << "--password" << @password if @password
#      options << "--revision" << revision_number(revision) if revision

      raise "#{path} is not empty, cannot clone a project into it" unless (Dir.entries(path) - ['.', '..']).empty?
      FileUtils.rm_rf(path)

      # need to read from command output, because otherwise tests break
      git('clone', [@repository, path], :execute_locally => false) do |io|
        begin
          while line = io.gets
            stdout.puts line
          end
        rescue EOFError
        end
      end
    end

    def latest_revision
      git_output = git('log', ['-1', '--pretty=raw'])
      Git::LogParser.new.parse(git_output).first
    end
    
    protected

    def git(operation, arguments, options = {}, &block)
      command = ["git"]
# TODO: figure out how to handle the same thing with git
#      command << "--non-interactive" unless @interactive
      command << operation
      command += arguments.compact
      command

      execute_in_local_copy(command, options, &block)
    end

  end

end
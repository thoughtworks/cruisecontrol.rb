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

    def checkout(revision = nil, stdout = $stdout)
      raise 'Repository location is not specified' unless @repository

      raise "#{path} is not empty, cannot clone a project into it" unless (Dir.entries(path) - ['.', '..']).empty?
      FileUtils.rm_rf(path)

      # need to read from command output, because otherwise tests break
      git('clone', [@repository, path], :execute_in_current_directory => false) do |io|
        begin
          while line = io.gets
            stdout.puts line
          end
        rescue EOFError
        end
      end

      if revision
        git("reset", revision.number)
      end
    end

    def latest_revision
      load_new_changesets_from_origin
      git_output = git('log', ['-1', '--pretty=raw', 'origin/master'])
      Git::LogParser.new.parse(git_output).first
    end

    def update
      git("reset", ["--hard", "origin/master"])
    end

    def up_to_date?(reasons = [])
      _new_revisions = new_revisions
      if _new_revisions.empty?
        return false
      else
        reasons << _new_revisions
        return true
      end
    end

    protected

    def load_new_changesets_from_origin
      git("remote", ["update"])
    end

    def new_revisions
      load_new_changesets_from_origin
      git_output = git('log', ['--pretty=raw', 'HEAD..origin/master'])
      Git::LogParser.new.parse(git_output)
    end

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
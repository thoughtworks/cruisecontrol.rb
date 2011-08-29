module SourceControl
  class Bazaar < AbstractAdapter

    attr_accessor :repository

    def initialize(options = {})
      options = options.dup
      @path = options.delete(:path) || "."
      @error_log = options.delete(:error_log)
      @interactive = options.delete(:interactive)
      @repository = options.delete(:repository)
      raise "don't know how to handle '#{options.keys.first}'" if options.length > 0
    end

    def checkout(revision = nil, stdout = $stdout, checkout_path = path)
      raise 'Repository location is not specified' unless @repository

      raise "#{checkout_path} is not empty, cannot branch a project into it" unless (Dir.entries(checkout_path) - ['.', '..']).empty?
      FileUtils.rm_rf(checkout_path)

      args = [@repository, checkout_path]
      args << ['-r', revision.number] if revision
      bzr('branch', args, :execute_in_project_directory => false)
    end

    def latest_revision
      bzr('pull')
      bzr_output = bzr('log', ['-v', '-r', '-1'])
      Bazaar::LogParser.new.parse(bzr_output).first
    end

    def up_to_date?(reasons = [])
      repository = bzr('info').join("\n").match(/parent branch:\s+(.*)/)[1].strip
      bzr_local = bzr('revno').first.to_i
      bzr_remote = bzr('revno', [repository]).first.to_i

      if bzr_remote == bzr_local
        return true
      elsif bzr_local > bzr_remote
        raise "Local repository is bigger, which should be impossible!"
      else
        bzr_output = bzr('missing', ['-v'], :exitstatus => 1)
        _new_revisions = Bazaar::LogParser.new.parse(bzr_output)
        reasons.concat(_new_revisions)
        return false
      end
    end

    def update(revision = nil)
      if revision
        bzr("revert", ['-r', revision.number])
      else
        bzr("pull")
      end
    end

    def creates_ordered_build_labels?() true end

    def clean_checkout(revision = nil, stdout = $stdout)
      update(revision)
      bzr("clean-tree")
    end

    protected

    def bzr(operation, arguments = [], options = {}, &block)
      command = ["bzr", operation] + arguments.compact
      ## TODO: figure out how to handle the same thing with hg
      ##      command << "--non-interactive" unless @interactive
      execute_in_local_copy(command, options, &block)
    end

  end
end

module SourceControl
  class AbstractAdapter

    include CommandLine
    
    attr_accessor :path

    def checkout(stdout = $stdout)
      raise NotImplementedError, "checkout() not implemented by #{self.class}"
    end

    def latest_revision
      raise NotImplementedError, "latest_revision() not implemented by #{self.class}"
    end

    def error_log
      @error_log ? @error_log : File.join(@path, "..", "source_control.err")
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
        stdin_output = io.readlines
        begin
          error_message = File.open(error_log){|f|f.read}.strip.split("\n")[1] || ""
        rescue
          error_message = ""
        ensure
          FileUtils.rm_f(error_log)
        end
        raise BuilderError.new(error_message, "source_control_error") unless error_message.empty?
        return stdin_output
      end
    end

  end
end

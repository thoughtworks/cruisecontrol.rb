module SourceControl
  class AbstractAdapter

    include CommandLine
    
    attr_accessor :path

    def checkout(revision = nil, stdout = $stdout)
      raise NotImplementedError, "checkout() not implemented by #{self.class}"
    end

    def latest_revision
      raise NotImplementedError, "latest_revision() not implemented by #{self.class}"
    end

    def up_to_date?(reasons = [])
      raise NotImplementedError, "up_to_date?() not implemented by #{self.class}"
    end

    def update(revision = nil)
      raise NotImplementedError, "update() not implemented by #{self.class}"
    end

    def creates_ordered_build_labels?
      raise NotImplementedError, "creates_ordered_build_labels?() not implemented by #{self.class}"
    end

    def clean_checkout(revision = nil, stdout = $stdout)
      new_path = "#{path}.new"
      begin
        checkout(revision, stdout, new_path)
        FileUtils.rm_rf(path)
        FileUtils.mv(new_path, path) if File.directory?(new_path)
      ensure
        FileUtils.rm_rf(new_path)
      end
    end

    def error_log
      @error_log ? @error_log : File.join(@path, "..", "source_control.err")
    end

    def execute_in_local_copy(command, options, &block)
      options = {:execute_in_project_directory => true}.merge(options)
      if block_given?
        if options[:execute_in_project_directory]
          Dir.chdir(path) do
            execute(command, options, &block)
          end
        else
          execute(command, options, &block)
        end
      else
        error_log = File.expand_path(self.error_log)
        if options[:execute_in_project_directory]
          raise "path is nil" if path.nil?
          Dir.chdir(path) do
            execute_with_error_log(command, error_log, options)
          end
        else
          execute_with_error_log(command, error_log, options)
        end
      end
    end

    def execute_with_error_log(command, error_log, options = {})
      options = {:stderr => error_log}.merge(options)
      FileUtils.rm_f(error_log)
      FileUtils.touch(error_log)
      stdout_output = nil
      execute(command, options) do |io|
        stdout_output = io.readlines
        File.open(error_log, "a") {|f| f << stdout_output}
      end
      stdout_output
    rescue ExecutionError => e
      raise BuilderError.new(File.read(error_log), "source_control_error")
    end

  end
end

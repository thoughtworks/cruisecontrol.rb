
require 'rant/rantlib'

module Rant          # :nodoc:
  module Generators  # :nodoc:
  class Rcov         # :nodoc:
    def self.rant_gen(app, ch, args, &block)
      if !args || args.empty?
        self.new(app, ch, &block)
      elsif args.size == 1
        name, pre = app.normalize_task_arg(args.first, ch)
        self.new(app, ch, name, pre, &block)
      else
        app.abort_at(ch,
                     "Rcov takes only one additional argument, " +
                     "which should be like one given to the `task' command.")
      end
    end

    attr_accessor :verbose
    attr_accessor :libs
    attr_accessor :test_dirs
    attr_accessor :pattern
    attr_accessor :test_files
    attr_accessor :rcov_opts
    # Directory where to put the generated XHTML reports
    attr_accessor :output_dir

    def initialize(app, cinf, name = :rcov, prerequisites = [], &block)
      @rac = app
      @name = name
      @pre = prerequisites
      #@block = block
      @verbose = nil
      cf = cinf[:file]
      @libs = []
      libdir = File.join(File.dirname(File.expand_path(cf)), 'lib')
      @libs << libdir if test(?d, libdir)
      @rcov_opts = ["--text-report"]
      @test_dirs = []
      @pattern = nil
      @test_files = nil
      yield self if block_given?
      @pattern = "test*.rb" if @pattern.nil? && @test_files.nil?
      @output_dir ||= "coverage"

      @pre ||= []
      # define the task
      app.task(:__caller__ => cinf, @name => @pre) { |t|
        args = []
        if @libs && !@libs.empty?
          args << "-I#{@libs.join File::PATH_SEPARATOR}"
        end
        if rcov_path = ENV['RCOVPATH'] 
          args << rcov_path
        else
          args << "-S" << "rcov"
        end
        args.concat rcov_opts
        args << "-o" << @output_dir
        if test(?d, "test")
          @test_dirs << "test" 
        elsif test(?d, "tests")
          @test_dirs << "tests"
        end
        args.concat filelist
        app.context.sys.ruby args
      }
    end
    
    def filelist
      return @rac.sys[@rac.var['TEST']] if @rac.var['TEST']
      filelist = @test_files || []
      if filelist.empty?
        if @test_dirs && !@test_dirs.empty?
          @test_dirs.each { |dir|
            filelist.concat(@rac.sys[File.join(dir, @pattern)])
          }
        else
          filelist.concat(@rac.sys[@pattern]) if @pattern
        end
      end
      filelist
    end
  end	# class Rcov
  end   # module Generators
end	# module Rant

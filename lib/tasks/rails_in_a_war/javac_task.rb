require 'rake/tasklib'
module RailsInAWar
  class JavacTask < Rake::TaskLib
    
    attr_accessor :target
    attr_accessor :source
    attr_accessor :classpath
    
    attr_accessor :src_dir
    attr_accessor :dest_dir
    
    def initialize(name=:javac)
      @name = name
      @target = '1.6'
      @source = '1.6'
      @classpath = []

      yield self if block_given?
      define
    end
    
    def define
      task @name do
        mkdir_p @dest_dir
        
        if !Dir["#{@src_dir}/**/*.java"].empty?
          create_sources_file
          create_classpath_file
          create_options_file
  
          javac = ['javac']
          javac << "@#{options_file}"
          javac << '-classpath'
          javac << "@#{classpath_file}"
          javac << '-sourcepath'
          javac << @src_dir
          javac << '-d'
          javac << @dest_dir
          javac << "@#{sources_file}"
          sh(javac.join(' '))
        end
      end
    end
    
    private
    def create_sources_file
      File.open(sources_file, 'w') do |f|
        f.puts(Dir["#{@src_dir}/**/*.java"])
      end
    end

    def create_classpath_file
      File.open(classpath_file, 'w') do |f|
        f.puts(@classpath.flatten.sort.join(File::PATH_SEPARATOR))
      end
    end
    
    def create_options_file
      File.open(options_file, 'w') do |f|
        f.puts '-g:lines,vars,source'
        f.puts "-source #{source}"
        f.puts "-target #{target}"
        f.puts '-encoding utf-8'
        f.puts '-nowarn'
      end
    end
    
    def tmp_dir
      dir = "#{Rails.root}/tmp"
      mkdir_p dir unless File.exist?(dir)
      dir
    end

    def options_file
      File.join(tmp_dir, '_javac_options')
    end

    def classpath_file
      File.join(tmp_dir, '_javac_classpath')
    end

    def sources_file
      File.join(tmp_dir, '_javac_sources')
    end
  end
end
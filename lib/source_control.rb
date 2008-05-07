module SourceControl

  class << self

    def create(scm_options)
      raise ArgumentError, "options should include repository" unless scm_options[:repository] 

      scm_options = scm_options.dup
      scm_type = scm_options.delete(:source_control)

      if scm_type.nil?
        source_control_class =
          case scm_options[:repository]
          when /^git:/ then Git
          when /^svn:/, /^svn\+ssh:/ then SourceControl::Subversion
          else SourceControl::Subversion
          end
      else
        scm_type = "subversion" if scm_type == "svn"
        scm_type = "mercurial" if scm_type == "hg"
        
        source_control_class_name = scm_type.to_s.camelize
        begin
          source_control_class = ("SourceControl::" + source_control_class_name).constantize
        rescue => e
          raise "#{scm_type.inspect} is not a valid --source-control value [#{e.message}]"
        end

        unless source_control_class.ancestors.include?(SourceControl::AbstractAdapter)
          raise "#{scm_type} is not a valid --source-control value " +
                "[#{source_control_class_name} is not a subclass of SourceControl::AbstractAdapter]"
        end
      end

      source_control_class.new(scm_options)
    end

    def detect(path)
      git = File.directory?(File.join(path, '.git'))
      svn = File.directory?(File.join(path, '.svn'))
      hg = File.directory?(File.join(path, '.hg'))

      case [git, svn, hg]
      when [true, false, false] then SourceControl::Git.new(:path => path)
      when [false, true, false] then SourceControl::Subversion.new(:path => path)
      when [false, false, true] then SourceControl::Mercurial.new(:path => path)
      when [false, false, false] then raise "Could not detect the type of source control in #{path}"
      else raise "More than one type of source control was detected in #{path}"
      end
    end

  end
end
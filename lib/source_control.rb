module SourceControl

  DEFAULT_SCM = "subversion"

  class << self

    def create(scm_options)
      raise ArgumentError, "options should include repository" unless scm_options[:repository]
      scm_type = scm_options[:source_control]

      source_control_class = if scm_type.nil?
        class_for simple_detect(scm_options[:repository])
      else
        class_for scm_type
      end

      unless source_control_class.ancestors.include?(SourceControl::AbstractAdapter)
        raise "#{scm_type} is not a valid --source-control value " +
                "[#{source_control_class_name} is not a subclass of SourceControl::AbstractAdapter]"
      end

      source_control_class.new(scm_options.except(:source_control))
    rescue NameError => e
      raise "#{scm_type.inspect} is not a valid --source-control value [#{e.message}]"
    end

    def simple_detect(url)
      case url
      when /^git:/ then "git"
      when /^svn:/, /^svn\+ssh:/ then "subversion"
      when /^bzr:/, /^bzr\+ssh:/ then "bazaar"
      else "subversion"
      end        
    end

    def detect(path)
      git = File.directory?(File.join(path, '.git'))
      svn = File.directory?(File.join(path, '.svn'))
      hg = File.directory?(File.join(path, '.hg'))
      bzr = File.directory?(File.join(path, '.bzr'))

      case [git, svn, hg, bzr]
      when [true, false, false, false] then SourceControl::Git.new(:path => path)
      when [false, true, false, false] then SourceControl::Subversion.new(:path => path)
      when [false, false, true, false] then SourceControl::Mercurial.new(:path => path)
      when [false, false, false, true] then SourceControl::Bazaar.new(:path => path)
      when [false, false, false, false] then raise "Could not detect the type of source control in #{path}"
      else raise "More than one type of source control was detected in #{path}"
      end
    end

    private

      def class_for(scm_name)
        case scm_name
        when /svn/i, /subversion/i then SourceControl::Subversion
        when /git/i                then SourceControl::Git
        when /bzr/i, /bazaar/i     then SourceControl::Bazaar
        when /hg/i,  /mercurial/i  then SourceControl::Mercurial
        else scm_name.classify.constantize
        end
      end

  end
end
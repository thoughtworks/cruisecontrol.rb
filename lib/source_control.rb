module SourceControl

  DEFAULT_SCM = "git"

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
      when /^svn:/, /^svn\+ssh:/ then "subversion"
      when /^bzr:/, /^bzr\+ssh:/ then "bazaar"
      when /^svn/, /^subversion/, /^svn\+ssh:/ then "subversion"
      else "git"
      end
    end

    def detect(path)
      git = File.directory?(File.join(path, '.git'))
      svn = File.directory?(File.join(path, '.svn'))
      hg = File.directory?(File.join(path, '.hg'))
      bzr = File.directory?(File.join(path, '.bzr'))
      
      raise "Could not detect the type of source control in #{path}"       unless [git, svn, hg, bzr].include?(true)
      raise "More than one type of source control was detected in #{path}" if [git, svn, hg, bzr].count(true) > 1
      
      return SourceControl::Git.new(:path => path)          if git
      return SourceControl::Subversion.new(:path => path)   if svn
      return SourceControl::Mercurial.new(:path => path)    if hg
      return SourceControl::Bazaar.new(:path => path)       if bzr
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

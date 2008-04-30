module SourceControl
  class << self

    def create(scm_options)
      raise ArgumentError, "options should include URL" unless scm_options[:url] 

      scm_options = scm_options.dup
      scm_type = scm_options.delete(:source_control)

      if scm_type.nil?
        source_control_class =
          case scm_options[:url]
          when /^git:/ then Git
          when /^svn:/, /^svn\+ssh:/ then Subversion
          else Subversion
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

    def detect(project_name)
      SourceControl::Subversion.new
    end

  end
end
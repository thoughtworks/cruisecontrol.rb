module SourceControl
  class << self

    def create(options)
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
        source_control_class_name = scm_options[:source_control].to_s.camelize

        begin
          source_control_class = source_control_class_name.constantize
        rescue => e
          raise "#{scm_options[:source_control].inspect} is not a valid --source-control value [#{e.message}]"
        end

        unless source_control_class.ancestors.include?(AbstractSourceControlAdapter)
          raise "#{scm_options[:source_control].inspect} is not a valid --source-control value " +
                "[#{source_control_class_name} is not a subclass of AbstractSourceControlAdapter]"
        end
      end

      source_control_class.new(scm_options)
    end

    def detect(project_name)
      SourceControl::Subversion.new
    end

  end
end
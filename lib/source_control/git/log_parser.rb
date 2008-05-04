module SourceControl
  class Git
    class LogParser

      def parse(log)
        return [Git::Revision.new]
      end

    end
  end
end


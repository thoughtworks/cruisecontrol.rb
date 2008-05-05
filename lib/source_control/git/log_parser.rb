module SourceControl
  class Git
    class LogParser

      def parse(log)
        return [Git::Revision.new(nil, nil, nil)]
      end

    end
  end
end


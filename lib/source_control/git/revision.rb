module SourceControl
  class Git
    class Revision < AbstractRevision
      attr_reader :number, :author, :time 

      def initialize(number, author, time)
        @number, @author, @time = number, author, time
      end

      def ==(other)
        other.is_a?(Git::Revision) && number == other.number
      end

      def to_s
        description = "Revision #{number} committed by #{author}"
        description << " on #{time.strftime('%Y-%m-%d %H:%M:%S')}" if time
        description
      end
    end
  end
end

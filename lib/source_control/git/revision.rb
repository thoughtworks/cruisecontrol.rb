module SourceControl
  class Git
    class Revision < AbstractRevision

      attr_reader :number, :committed_by, :time 

      def initialize(number, committed_by, time)
        @number, @committed_by, @time = number, committed_by, time
      end

      def ==(other)
        other.is_a?(Git::Revision) && number == other.number
      end

      def inspect
        "Git::Revision(#{number})"
      end

    end
  end
end
module SourceControl
  class Git
    class Revision < AbstractRevision

      include Comparable

      attr_reader :number, :committed_by, :time 

      def initialize(number, committed_by, time)
        @number, @committed_by, @time = number, committed_by, time
      end

      def <=>(other)
        0
      end

    end
  end
end
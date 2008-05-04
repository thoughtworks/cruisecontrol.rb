module SourceControl
  class Git
    class Revision < AbstractRevision

      include Comparable

      def initiailize
      end


      def <=>(other)
#        raise("Comparing a revision to #{other.class} is not supported") unless other.is_a? Revision
        0
      end

    end
  end
end
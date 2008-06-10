module SourceControl
  class Subversion

    class Revision < AbstractRevision
      include Comparable

      attr_reader :number, :author, :time, :message, :changeset

      def initialize(number, author = nil, time = nil, message = nil, changeset = nil)
        @number = number.to_i
        @author, @time, @message, @changeset = author, time, message, changeset
      end

      def to_s
        <<-EOL
Revision #{number} committed by #{author} on #{time.strftime('%Y-%m-%d %H:%M:%S') if time}
#{message}
#{changeset ? changeset.collect { |entry| entry.to_s }.join("\n") : nil}
        EOL
      end

      def <=>(other)
        raise("Comparing a revision to #{other.class} is not supported") unless other.is_a? Revision
        @number <=> other.number
      end

      def ==(other)
        @number == other.number
      end

      def to_i
        @number
      end

    end

  end
end

module SourceControl
  class Mercurial

  # FIXME: Mercurial revision is almost same as Subversion revision; and Git is not much different. Remove redundancy.
  class Revision < AbstractRevision

      attr_reader :number, :author, :time, :message, :changeset

      def initialize(number, author = nil, time = nil, message = nil, changeset = nil)
        @number = number
        @author, @time, @message, @changeset = author, time, message, changeset
      end

      def to_s
        <<-EOL
Revision #{number} committed by #{author} on #{time.strftime('%Y-%m-%d %H:%M:%S') if time}
#{message}
#{changeset ? changeset.collect { |entry| entry.to_s }.join("\n") : nil}
        EOL
      end

      def ==(other)
        @number == other.number
      end

      def to_i
        @number.to_i
      end

    end
  end
end

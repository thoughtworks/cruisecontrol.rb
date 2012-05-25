module SourceControl
  class Bazaar

    class Revision < AbstractRevision

      attr_reader :number, :author, :time, :message, :changeset

      def initialize(number, author = nil, time = nil, message = nil, changeset = nil)
        @number = number
        @author, @time, @message, @changeset = author, time, message, changeset
      end

      def to_s
        output = "Revision #{number}"
        output << " committed by #{author}" if author
        output << " on #{time.strftime('%Y-%m-%d %H:%M:%S')}" if time
        output << "\n\n#{message}" if message
        output << "\n\n#{changeset.map(&:to_s).join("\n")}" if changeset
        output << "\n"
        output
      end

      def <=>(other)
        @number <=> other.number
      end

      def ==(other)
        [:class, :number, :author, :time, :message, :changeset].all? do |p|
          other.send(p) == self.send(p)
        end
      end

      def to_i
        @number.to_i
      end

    end
  end
end

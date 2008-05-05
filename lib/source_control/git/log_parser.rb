module SourceControl
  class Git
    class LogParser

      def parse(log)
        @result = []

        log.each_line do |line|
          line.chomp!
          line == "" ? next : process_line(line)
        end

        @result << Git::Revision.new(@id, @author, @time) if @commit_message

        return @result
      end

      private

      def process_line(line)
        if commit_message?(line)
          @commit_message ||= true
#          @commit_message += line.sub('    ', '')
        else
          add_current_revision_to_result
          parse_line(line)
        end
      end

      def parse_line(line)
        match = line.match(/^(\w+) (.*)$/)
        key, value = match[1,2]

        case key
        when 'commit' then @id = value
        when 'author' then parse_author(value)
        else  # ignore other keys
        end
      end

      def parse_author(author_value)
        @author, seconds_from_epoch = author_value.match(/^(.+) (\d+) [-+]\d{4}$/)[1, 2]
        @time = Time.at(seconds_from_epoch.to_i)
      end

      def commit_message?(line)
        line[0, 4] == '    '
      end

      def add_current_revision_to_result
        if @commit_message
          @result << Git::Revision.new(@id, @author, @time)
          @id = @author = @time = nil
        end
      end

    end
  end
end


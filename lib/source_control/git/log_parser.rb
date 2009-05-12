module SourceControl
  class Git
    class LogParser
      def parse(log)
        @log = log
        revisions = []
        revision = nil
        
        log.each do |line|
          next if line.blank?
          line.chomp!
          case line
          when /^commit /
            revisions << revision = Revision.new
            revision.number = line.split[1][0..6]
            
          when /^author /
            revision.author, revision.time = read_author_and_time(line)
            
          when /^    /
            (revision.message ||= []) << line.strip
            
          when /^ /
            (revision.changeset ||= []) << line.strip
            
          when /^tree /
          when /^parent /
          when /^committer /
            # don't care
            
          else
            raise "don't know how to parse #{line}"
          end
        end

        revisions.each do |revision|
          revision.message = revision.message.join("\n") if revision.message
          revision.summary = revision.changeset.pop if revision.changeset
        end
        revisions
      end

      private
      
      def read_author_and_time(line)
        author, seconds_from_epoch = line.match(/^author (.+) (\d+) [-+]\d{4}$/)[1, 2]
        [author, Time.at(seconds_from_epoch.to_i)]
      end
    end
  end
end

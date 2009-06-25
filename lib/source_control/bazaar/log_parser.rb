require 'date'

module SourceControl
  class Bazaar
    class LogParser

      def parse(message)

        revisions = []

        entries = split_log(message)

        entries.each do |entry|
          rev_number = parse_for_rev_number(entry)
          name = parse_for_name(entry)
          date = parse_for_date(entry)
          message, files = parse_for_message_and_files(entry)
          change_set_entries = []
          files.each do |file_name|
            change_set_entries << ChangesetEntry.new("", file_name)
          end
          revisions << Revision.new(rev_number, name, date, message, change_set_entries)
        end

        revisions
      end

      def parse_for_name(message)
        name_match = (message.match(/^committer:\s+(.*)\</) ||
                     message.match(/^committer:\s+(.*)$/))
        name_match[1].strip
      end

      def parse_for_date(message)
        date_string = message.match(/^timestamp:\s+(.*)/)[1].strip
        DateTime.parse(date_string)
      end

      def parse_for_message_and_files(message)
        message, files_text = message.match(/^message:.(.*)^(modified|added|renamed|removed):(.*)/m)[1..2]
        files = files_text.split(/\s+/)
        %w{modified: added: renamed: removed:}.each do |header|
          files.delete(header)
        end
        [message, files]
      end

      def parse_for_rev_number(message)
        message.match(/^revno:\s+(\d+)/)[1]
      end

      def split_log(message)
        message = message.join("\n") if message.is_a? Array
        if message.match(/Branches are up to date/)
          return []
        end
        message.split(/^\s+$/).delete_if {|t| t =~ /^\s+$/ }.map(&:strip)
      end

    end
  end
end

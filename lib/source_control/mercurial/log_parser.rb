require 'date'

module SourceControl
  class Mercurial
    class LogParser

      def parse(message)

        revisions = []

        entries = split_log(message)

        entries.each do |entry|
          rev_number = parse_for_rev_number(entry)
          name = parse_for_name(entry)
          date = parse_for_date(entry)
          message = parse_for_message(entry)
          change_set_entries = []
          files = parse_for_files(entry)
          files.each do |file_name|
            change_set_entries << ChangesetEntry.new("", file_name)
          end
          revisions << Revision.new(rev_number, name, date, message, change_set_entries)
        end

        revisions
      end

      def parse_for_name(message)
        name_match = (message.match(/^user:\s+(.*)\</) ||
                     message.match(/^user:\s+(.*)$/))
        name_match[1].strip
      end

      def parse_for_date(message)
        date_string = message.match(/^date:\s+(.*)(\+|\-)\d+$/)[1].strip
        DateTime.parse(date_string)
      end

      def parse_for_message(message)
        message.match(/^description:\s*(.*)/)[1]
      end

      def parse_for_rev_number(message)
        message.match(/^changeset:\s+\d+:(.....)/)[1]
      end

      def parse_for_files(message)
        match = message.match(/^files:\s+(.*)/)
        match ? match[1].split(/\s/) : []
      end

      def split_log(message)
        message = message.join("\n") if message.is_a? Array
        message.split(/^\s+$/).delete_if {|t| t =~ /^\s+$/ }.map(&:strip)
      end

    end
  end
end

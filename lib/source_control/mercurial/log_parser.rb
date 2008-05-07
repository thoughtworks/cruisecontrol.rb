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
        message =~ /user:\s+(.*)\</
        $1.strip!
      end

      def parse_for_date(message)
        message =~ /date:\s+(.*)(\+|\-)\d+$/
        DateTime.parse($1.strip!)
      end

      def parse_for_message(message)
        message =~ /description:\s*(.*)/
        $1
      end

      def parse_for_rev_number(message)
        message =~ /changeset:\s+(\d+)/
        $1.to_i
      end

      def parse_for_files(message)
        message =~ /files:\s+(.*)/
        $1.split(/\s/)
      end

      def split_log(message)
        message = message.join("\n") if message.is_a? Array

        message.split(/^\s+$/).delete_if {|t| t =~ /^\s+$/ }.map(&:strip)
      end

    end
  end
end

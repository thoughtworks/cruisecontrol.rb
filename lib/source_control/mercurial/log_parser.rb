require 'date'

module SourceControl
  class Mercurial
    class LogParser

      def parse_log(log_message)

        revisions = []

        entries = split_log(log_message)

        entries.each do |log_entry|
          rev_number = parse_for_rev_number(log_entry)
          name = parse_for_name(log_entry)
          date = parse_for_date(log_entry)
          message = parse_for_message(log_entry)
          change_set_entries = []
          files = parse_for_files(log_entry)
          files.each do |file_name|
            change_set_entries << ChangesetEntry.new("", file_name)
          end
          revisions << Revision.new(rev_number, name, date, message, change_set_entries)
        end

        revisions
      end

      def parse_for_name(log_message)
        log_message =~ /user:\s+(.*)\</
        $1.strip!
      end

      def parse_for_date(log_message)
        log_message =~ /date:\s+(.*)(\+|\-)\d+$/
        DateTime.parse($1.strip!)
      end

      def parse_for_message(log_message)
        log_message =~ /description:\s*(.*)/
        $1
      end

      def parse_for_rev_number(log_message)
        log_message =~ /changeset:\s+(\d+)/
        $1.to_i
      end

      def parse_for_files(log_message)
        log_message =~ /files:\s+(.*)/
        $1.split(/\s/)
      end

      def split_log(log_message)
        split = log_message.split(/^\s+$/)
        split.delete_if {|t| t =~ /^\s+$/ }
        split.each {|t| t.strip!}
        split
      end

    end
  end
end

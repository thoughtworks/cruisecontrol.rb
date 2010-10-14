require 'date'
require 'rexml/document'

module SourceControl
  class Bazaar
    class LogParser

      def parse(source)
        revisions = []

        xml = REXML::Document.new(source.join(""))

        xml.elements.each("//log") do |log|
          rev_number = parse_for_rev_number(log)
          name = parse_for_name(log)
          date = parse_for_date(log)
          message = parse_for_message(log)
          changesets = parse_for_changesets(log)
          revisions << Revision.new(rev_number, name, date, message, changesets)
        end

        revisions
      end

      def parse_for_rev_number(log)
        log.elements.to_a("./revno").first.text rescue nil
      end

      def parse_for_name(log)
        log.elements.to_a("./committer").first.text rescue nil
      end

      def parse_for_date(log)
        Time.parse(log.elements.to_a("./timestamp").first.text) rescue nil
      end

      def parse_for_message(log)
        log.elements.to_a("./message").first.text rescue nil
      end

      CHANGE_TYPE_MAP = [
        ["modified",     "M"],
        ["renamed",      "R"],
        ["kind-changed", "C"],
        ["removed",      "D"],
        ["added",        "A"],
      ]
      def parse_for_changesets(log)
        changesets = []
        log.elements.each("./affected-files") do |affected_files|
          CHANGE_TYPE_MAP.each do |element, abbr|
            type = affected_files.elements.to_a("./#{element}").first
            next unless type
            type.elements.each do |item|
              text = if element == "renamed"
                "%s => %s" % [item.text, item.attributes["oldpath"]]
              else
                item.text
              end
              changesets << ChangesetEntry.new(abbr, text)
            end
          end
        end
        changesets
      end

    end
  end
end

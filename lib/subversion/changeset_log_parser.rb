class Subversion::ChangesetLogParser
  def parse_log(lines)
    return [] if lines.empty?
    revisions = []
    begin
      while not lines.empty?
        revision = parse_revision(lines)
        revisions << revision
      end
    rescue
      # Do nothing, the changeset is malformed.
    end
    revisions   
  end

  REVISION_PATTERN = /^Revision (\d+\.*\d*) committed by (\S+) on (\d+-\d+-\d+ \d+:\d+:\d+)$/
  CHANGESET_PATTERN = /^\s*(\S+)\s+(.*)$/
  CHANGESET_START_PATTERN = /^\s\s(\S).*$/

  def parse_revision(lines)
   number, committed_by, time = REVISION_PATTERN.match(lines.shift)[1..3]

   comment_lines = []
   while (line = lines.shift) and line !~ CHANGESET_START_PATTERN
     comment_lines << line.strip
   end   
   revision = Revision.new(number.to_f, committed_by, DateTime.parse(time),
                           comment_lines.join("\n"), [])

   begin
     match = CHANGESET_PATTERN.match(line)
     revision.changeset << ChangesetEntry.new($1.strip, $2) if match
   end until !(line = lines.shift) or line.empty?         
   revision
  end
end
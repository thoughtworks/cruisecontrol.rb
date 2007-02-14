class ChangesetLogParser

  def parse_log(lines)
    return [] if lines.empty?
    revisions = []
    while not lines.empty?
      revision = parse_revision(lines)
      revisions << revision
    end
    revisions   
  end

  REVISION_PATTERN = /^Revision (\d+\.*\d*) committed by (\S+) on (\d+-\d+-\d+ \d+:\d+:\d+)$/
  CHANGESET_PATTERN = /^\s*(\S+)\s+(.*)$/
  CHANGESET_START_PATTERN = /^\s\s(\S).*$/

  def parse_revision(lines)  
   number, committed_by, time = REVISION_PATTERN.match(lines.shift)[1..3]
   revision = Revision.new(number.to_f, committed_by, DateTime.parse(time), '', [])

   comment_lines = []
   while (line = lines.shift) and not line.strip.empty? and line !~ CHANGESET_START_PATTERN
     comment_lines << line
   end   
   revision.message = comment_lines.join("\n") unless comment_lines.empty?
   
   begin
     match = CHANGESET_PATTERN.match(line)
     # TODO: Handle if match is false        
     revision.changeset << ChangesetEntry.new($1.strip, $2)   
   end until !(line = lines.shift) or line.empty?         
   revision
  end
end
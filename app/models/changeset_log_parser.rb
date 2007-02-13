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

  def parse_revision(lines)  
    number, committed_by, time = REVISION_PATTERN.match(lines.shift)[1..3]
    revision = Revision.new(number.to_f, committed_by, DateTime.parse(time), '', [])
    
    # TODO: Can the message span multiple lines?   
    revision.message << (line = lines.shift)
    revision.message.strip!

    while (line = lines.shift) and not line.strip.empty?  do
      match = CHANGESET_PATTERN.match(line)
      # TODO: Handle if match is false        
      operation, file = match[1..2]
      ChangesetEntry.new(operation.strip, file)
      revision.changeset << ChangesetEntry.new(operation, file)
    end    
    revision
  end
end
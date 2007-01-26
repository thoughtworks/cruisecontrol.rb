require 'date'

class SubversionLogParser

  def parse_log(lines)
    return [] if lines.empty?
    lines.shift #ignore first dashed line

    revisions = []
    while not lines.empty?
      revision = parse_revision(lines)
      revisions << revision
    end

  revisions
  end

  UPDATE_PATTERN = /^(...)  (\S.*)$/
  def parse_update(lines)
    lines[0..-2].collect do |line|
      match = UPDATE_PATTERN.match(line)
      if match
        operation, file = match[1..2]
        ChangesetEntry.new(operation, file)
      else
        nil
      end
    end.compact
  end

  private

  REVISION_PATTERN = /^r(\d+) \| ([^|]+) \| ([^|]+) \| .*$/
  CHANGESET_PATTERN = /^\s*(\S+)\s+(.*)$/
  def parse_revision(lines)
    number, committed_by, time = REVISION_PATTERN.match(lines.shift)[1..3]
    revision = Revision.new(number.to_i, committed_by, DateTime.parse(time), '', [])

    line = lines.shift
    if line =~ /^Changed paths:/
      while (line = lines.shift) and not line.strip.empty?  do
        match = CHANGESET_PATTERN.match(line)
        raise "Line #{line.inspect} does not like a changeset line from 'svn log --verbose'" unless match
        operation, file = match[1..2]
        ChangesetEntry.new(operation.strip, file)
        revision.changeset << ChangesetEntry.new(operation, file)
      end
    end

    revision.message << line while (line = lines.shift).strip != '-' * 72
    revision.message.strip!

    revision
  end
end
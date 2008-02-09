class Subversion::UpdateParser

  UPDATE_PATTERN = /^(...)  (\S.*)$/
  def parse(lines)
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

end
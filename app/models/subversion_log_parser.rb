require 'date'
require 'xml_simple'

class SubversionLogParser

  def parse_log(lines)
    return [] if lines.empty?
    entries = XmlSimple.xml_in(lines.join, 'ForceArray' => ['logentry','path'])['logentry'] || []
    entries.map {|entry| parse_revision(entry) }
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

  def parse_info(xml)
    info = XmlSimple.xml_in(xml.to_s, 'ForceArray' => false)['entry']
    Subversion::Info.new(info['revision'].to_i, info['commit']['revision'].to_i, info['commit']['author'])
  end

  private
  
  def parse_revision(hash)
    changesets = hash.fetch('paths', {}).fetch('path', {}).map do |entry| 
      ChangesetEntry.new(entry['action'], entry['content'])
    end
    
    date = hash['date'] ? DateTime.parse(hash['date']) : nil
    message = hash['msg'] == {} ? nil : hash['msg']
    Revision.new(hash['revision'].to_i, hash['author'], date, message, changesets)
  end
end
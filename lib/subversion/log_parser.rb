require 'date'
require 'xml_simple'

class Subversion::LogParser
  def parse(lines)
    return [] if lines.empty?
    entries = XmlSimple.xml_in(lines.join, 'ForceArray' => ['logentry','path'])['logentry'] || []
    entries.map {|entry| parse_revision(entry) }
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
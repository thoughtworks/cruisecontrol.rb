require 'xml_simple'

class SubversionInfoParser
  def parse(xml)
    info = XmlSimple.xml_in(xml.to_s, 'ForceArray' => false)['entry']
    Subversion::Info.new(info['revision'].to_i, info['commit']['revision'].to_i, info['commit']['author'])
  end
end
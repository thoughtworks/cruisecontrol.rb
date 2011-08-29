module SourceControl
  class Subversion

    class InfoParser
      def parse(xml)
        xml = xml.join if xml.is_a? Array
        info = XmlSimple.xml_in(xml.to_s, 'ForceArray' => false)['entry']
        Subversion::Info.new(info['revision'].to_i, info['commit']['revision'].to_i, info['commit']['author'], info['url'])
      end
    end
    
  end
end


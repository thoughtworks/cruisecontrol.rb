module SourceControl
  class Subversion

    class InfoParser
      def parse(xml)
        info = XmlSimple.xml_in(xml.join, 'ForceArray' => false)['entry']
        Subversion::Info.new(info['revision'].to_i, info['commit']['revision'].to_i, info['commit']['author'])
      end
    end
    
  end
end


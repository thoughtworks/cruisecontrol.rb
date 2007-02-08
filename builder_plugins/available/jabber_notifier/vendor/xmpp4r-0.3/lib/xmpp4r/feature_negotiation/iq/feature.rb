require 'xmpp4r/iq'
require 'xmpp4r/dataforms/x/data'

module Jabber
  module FeatureNegotiation
    ##
    # Feature negotiation,
    # can appear as direct child to Iq
    # or as child of IqSi
    class IqFeature < REXML::Element
      def initialize
        super('feature')

        add_namespace 'http://jabber.org/protocol/feature-neg'
      end

      def IqFeature.import(element)
        IqFeature::new.import(element)
      end

      def typed_add(element)
        if element.name == 'x' and element.namespace == 'jabber:x:data'
          super Dataforms::XData.new.import(element)
        else
          super element
        end
      end

      ##
      # First <x/> child with xmlns='jabber:x:data'
      def x
        res = nil
        each_element('x') { |e|
          res = e if e.namespace == 'jabber:x:data'
        }
        res
      end
    end

    Iq.add_elementclass('feature', IqFeature)
  end
end

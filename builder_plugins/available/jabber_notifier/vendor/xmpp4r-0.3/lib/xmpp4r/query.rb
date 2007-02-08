# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  ##
  # A class used to build/parse IQ Query requests/responses
  #
  class IqQuery < REXML::Element
    @@namespace_classes = {}

    ##
    # Initialize a <query/> element
    #
    # Does nothing more than setting the element's name to 'query'
    def initialize
      super("query")
    end

    ##
    # Create a new [IqQuery] from iq.query
    # element:: [REXML::Element] to import, will be automatically converted if namespace appropriate
    def IqQuery.import(element)
      if @@namespace_classes.has_key?(element.namespace)
        @@namespace_classes[element.namespace]::new.import(element)
      else
        IqQuery::new.import(element)
      end
    end

    ##
    # Add a class by namespace for automatic IqQuery conversion (see IqQuery.import)
    # ns:: [String] Namespace (e.g. 'jabber:iq:roster')
    # queryclass:: [IqQuery] Query class derived from IqQuery
    def IqQuery.add_namespaceclass(ns, queryclass)
      @@namespace_classes[ns] = queryclass
    end
  end

  Iq.add_elementclass('query', IqQuery)
end

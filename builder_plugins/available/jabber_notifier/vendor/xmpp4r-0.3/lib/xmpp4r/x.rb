# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/rexmladdons'

module Jabber
  ##
  # A class used to build/parse <x/> elements
  #
  # These elements may occur as "attachments"
  # in [Message] and [Presence] stanzas
  class X < REXML::Element
    @@namespace_classes = {}

    ##
    # Initialize a <x/> element
    #
    # Does nothing more than setting the element's name to 'x'
    def initialize
      super("x")
    end

    ##
    # Create a new [X] from an XML-Element
    # element:: [REXML::Element] to import, will be automatically converted if namespace appropriate
    def X.import(element)
      if @@namespace_classes.has_key?(element.namespace)
        @@namespace_classes[element.namespace]::new.import(element)
      else
        X::new.import(element)
      end
    end

    ##
    # Add a class by namespace for automatic X conversion (see X.import)
    # ns:: [String] Namespace (e.g. 'jabber:x:delay')
    # xclass:: [X] x class derived from X
    def X.add_namespaceclass(ns, xclass)
      @@namespace_classes[ns] = xclass
    end
  end
end

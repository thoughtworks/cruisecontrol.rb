# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/xmlstanza'
require 'xmpp4r/jid'
require 'digest/sha1'

module Jabber
  ##
  # IQ: Information/Query
  # (see RFC3920 - 9.2.3
  #
  # A class used to build/parse IQ requests/responses
  class Iq < XMLStanza
    @@element_classes = {}

    ##
    # Build a new <iq/> stanza
    # type:: [Symbol] or nil, see Iq#type
    # to:: [JID] Recipient
    def initialize(type = nil, to = nil)
      super("iq")
      if not to.nil?
        set_to(to)
      end 
      if not type.nil?
        set_type(type)
      end 
    end

    ##
    # Get the type of the Iq stanza
    #
    # The following values are allowed:
    # * :get
    # * :set
    # * :result
    # * :error
    # result:: [Symbol] or nil
    def type
      case super
        when 'get' then :get
        when 'set' then :set
        when 'result' then :result
        when 'error' then :error
        else nil
      end
    end

    ##
    # Set the type of the Iq stanza (see Iq#type)
    # v:: [Symbol] or nil
    def type=(v)
      case v
        when :get then super('get')
        when :set then super('set')
        when :result then super('result')
        when :error then super('error')
        else super(nil)
      end
    end

    ##
    # Set the type of the Iq stanza (chaining-friendly)
    # v:: [Symbol] or nil
    def set_type(v)
      self.type = v
      self
    end

    ##
    # Returns the iq's query child, or nil
    # result:: [IqQuery]
    def query 
      first_element('query')
    end

    ##
    # Delete old elements named newquery.name
    #
    # newquery:: [REXML::Element] will be added
    def query=(newquery)
      delete_elements(newquery.name)
      add(newquery)
    end

    ##
    # Returns the iq's query's namespace, or nil
    # result:: [String]
    def queryns 
      e = first_element('query')
      if e
        return e.namespace
      else
        return nil
      end
    end

    ##
    # Returns the iq's <vCard/> child, or nil
    # result:: [IqVcard]
    def vcard 
      first_element('vCard')
    end

    ##
    # Create a new iq from a stanza,
    # copies all attributes and children from xmlstanza
    # xmlstanza:: [REXML::Element] Source stanza
    # return:: [Iq] New stanza
    def Iq.import(xmlstanza)
      Iq::new.import(xmlstanza)
    end

    ##
    # Add an element to the Iq stanza
    # element:: [REXML::Element] Element to add.
    # Will be automatically converted (imported) to
    # a class registered with add_elementclass
    def typed_add(element)
      if element.kind_of?(REXML::Element) && @@element_classes.has_key?(element.name)
        super(@@element_classes[element.name]::import(element))
      else
        super(element)
      end
    end

    ##
    # Create a new Iq stanza with an unspecified query child
    # (<query/> has no namespace)
    def Iq.new_query(type = nil, to = nil)
      iq = Iq::new(type, to)
      query = IqQuery::new
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:auth set Stanza.
    def Iq.new_authset(jid, password)
      iq = Iq::new(:set)
      query = IqQuery::new
      query.add_namespace('jabber:iq:auth')
      query.add(REXML::Element::new('username').add_text(jid.node))
      query.add(REXML::Element::new('password').add_text(password))
      query.add(REXML::Element::new('resource').add_text(jid.resource)) if not jid.resource.nil?
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:auth set Stanza for Digest authentication
    def Iq.new_authset_digest(jid, session_id, password)
      iq = Iq::new(:set)
      query = IqQuery::new
      query.add_namespace('jabber:iq:auth')
      query.add(REXML::Element::new('username').add_text(jid.node))
      query.add(REXML::Element::new('digest').add_text(Digest::SHA1.new(session_id + password).hexdigest))
      query.add(REXML::Element::new('resource').add_text(jid.resource)) if not jid.resource.nil?
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:register set stanza for service/server registration
    # username:: [String] (Element will be ommited if unset)
    # password:: [String] (Element will be ommited if unset)
    def Iq.new_register(username=nil, password=nil)
      iq = Iq::new(:set)
      query = IqQuery::new
      query.add_namespace('jabber:iq:register')
      query.add(REXML::Element::new('username').add_text(username)) if username
      query.add(REXML::Element::new('password').add_text(password)) if password
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:roster get Stanza.
    #
    # IqQueryRoster is unused here because possibly not require'd
    def Iq.new_rosterget
      iq = Iq::new(:get)
      query = IqQuery::new
      query.add_namespace('jabber:iq:roster')
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:roster get Stanza.
    def Iq.new_browseget
      iq = Iq::new(:get)
      query = IqQuery::new
      query.add_namespace('jabber:iq:browse')
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:roster set Stanza.
    def Iq.new_rosterset
      iq = Iq::new(:set)
      query = IqQuery::new
      query.add_namespace('jabber:iq:roster')
      iq.add(query)
      iq
    end

    ##
    # Add a class by name.
    # Elements with this name will be automatically converted
    # to the specific class.
    # Used for <query/>, <vCard>, <pubsub> etc.
    # name:: [String] Element name
    # elementclass:: [Class] Target class
    def Iq.add_elementclass(name, elementclass)
      @@element_classes[name] = elementclass
    end
  end
end

# Actually these should be included at the top,
# but then they would be unable to call Iq.add_elementclass
# because it hasn't just been defined.

require 'xmpp4r/query'
require 'xmpp4r/vcard/iq/vcard'

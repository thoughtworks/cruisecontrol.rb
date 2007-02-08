require 'base64'
require 'digest/md5'

module Jabber
  ##
  # Helpers for SASL authentication (RFC2222)
  #
  # You might not need to use them directly, they are
  # invoked by Jabber::Client#auth
  module SASL
    NS_SASL = 'urn:ietf:params:xml:ns:xmpp-sasl'

    ##
    # Factory function to obtain a SASL helper for the specified mechanism
    def SASL::new(stream, mechanism)
      case mechanism
        when 'DIGEST-MD5'
          DigestMD5.new(stream)
        when 'PLAIN'
          Plain.new(stream)
        else
          raise "Unknown SASL mechanism: #{mechanism}"
      end
    end

    ##
    # SASL mechanism base class (stub)
    class Base
      def initialize(stream)
        @stream = stream
      end

      private

      def generate_auth(mechanism, text=nil)
        auth = REXML::Element.new 'auth'
        auth.add_namespace NS_SASL
        auth.attributes['mechanism'] = mechanism
        auth.text = text
        auth
      end

      def generate_nonce
        Digest::MD5.new(Time.new.to_f.to_s).hexdigest
      end
    end

    ##
    # SASL PLAIN authentication helper (RFC2595)
    class Plain < Base
      ##
      # Authenticate via sending password in clear-text
      def auth(password)
        auth_text = "#{@stream.jid.strip}\x00#{@stream.jid.node}\x00#{password}"
        error = nil
        @stream.send(generate_auth('PLAIN', Base64::encode64(auth_text).strip)) { |reply|
          if reply.name != 'success'
            error = reply.first_element(nil).name
          end
          true
        }
        
        raise error if error
      end
    end

    ##
    # SASL DIGEST-MD5 authentication helper (RFC2831)
    class DigestMD5 < Base
      ##
      # Sends the wished auth mechanism and wait for a challenge
      #
      # (proceed with DigestMD5#auth)
      def initialize(stream)
        super

        challenge = {}
        error = nil
        @stream.send(generate_auth('DIGEST-MD5')) { |reply|
          if reply.name == 'challenge' and reply.namespace == NS_SASL
            challenge_text = Base64::decode64(reply.text)
            challenge_text.split(/,/).each { |s|
              key, value = s.split(/=/, 2)
              value.sub!(/^"/, '')
              value.sub!(/"$/, '')
              challenge[key] = value
            }
          else
            error = reply.first_element(nil).name
          end
          true
        }
        raise error if error

        @nonce = challenge['nonce']
        @realm = challenge['realm']
      end

      ##
      # * Send a response
      # * Wait for the server's challenge (which aren't checked)
      # * Send a blind response to the server's challenge
      def auth(password)
        response = {}
        response['nonce'] = @nonce
        response['charset'] = 'utf-8'
        response['username'] = @stream.jid.node
        response['realm'] = @realm || @stream.jid.domain
        response['cnonce'] = generate_nonce
        response['nc'] = '00000001'
        response['qop'] = 'auth'
        response['digest-uri'] = "xmpp/#{@stream.jid.domain}"
        response['response'] = response_value(@stream.jid.node, @stream.jid.domain, response['digest-uri'], password, @nonce, response['cnonce'], response['qop'])
        response.each { |key,value|
          unless %w(nc qop response charset).include? key
            response[key] = "\"#{value}\""
          end
        }

        r = REXML::Element.new('response')
        r.add_namespace NS_SASL
        r.text = Base64::encode64(response.collect { |k,v| "#{k}=#{v}" }.join(',')).gsub(/\s/, '')
        error = nil
        @stream.send(r) { |reply|
          if reply.name != 'challenge'
            error = reply.first_element(nil).name
          end
          true
        }
        
        raise error if error

        # TODO: check the challenge from the server

        r.text = nil
        @stream.send(r) { |reply|
          if reply.name != 'success'
            error = reply.first_element(nil).name
          end
          true
        }
        
        raise error if error
      end

      private

      ##
      # Function from RFC2831
      def h(s); Digest::MD5.digest(s); end
      ##
      # Function from RFC2831
      def hh(s); Digest::MD5.hexdigest(s); end
      
      ##
      # Calculate the value for the response field
      def response_value(username, realm, digest_uri, passwd, nonce, cnonce, qop)
        a1_h = h("#{username}:#{realm}:#{passwd}")
        a1 = "#{a1_h}:#{nonce}:#{cnonce}"
        #a2 = "AUTHENTICATE:#{digest_uri}#{(qop == 'auth') ? '' : ':00000000000000000000000000000000'}"
        a2 = "AUTHENTICATE:#{digest_uri}"

        hh("#{hh(a1)}:#{nonce}:00000001:#{cnonce}:#{qop}:#{hh(a2)}")
      end
    end
  end
end

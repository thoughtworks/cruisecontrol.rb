# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'callbacks'
require 'socket'
require 'thread'
Thread::abort_on_exception = true
require 'xmpp4r/streamparser'
require 'xmpp4r/presence'
require 'xmpp4r/message'
require 'xmpp4r/iq'
require 'xmpp4r/errorexception'
require 'xmpp4r/debuglog'
require 'xmpp4r/idgenerator'

module Jabber
  ##
  # The stream class manages a connection stream (a file descriptor using which
  # XML messages are read and sent)
  class Stream
    DISCONNECTED = 1
    CONNECTED = 2

    # file descriptor used
    attr_reader :fd

    # connection status
    attr_reader :status

    ##
    # Create a new stream
    # (just initializes)
    def initialize(threaded = true)
      @fd = nil
      @status = DISCONNECTED
      @xmlcbs = CallbackList::new
      @stanzacbs = CallbackList::new
      @messagecbs = CallbackList::new
      @iqcbs = CallbackList::new
      @presencecbs = CallbackList::new
      unless threaded
        $stderr.puts "Non-threaded mode is currently broken, re-enabling threaded"
        threaded = true
      end
      @threaded = threaded
      @stanzaqueue = []
      @stanzaqueue_lock = Mutex::new
      @exception_block = nil
      @threadblocks = []
#      @pollCounter = 10
      @waiting_thread = nil
      @wakeup_thread = nil
      @streamid = nil
      @features_lock = Mutex.new
    end

    ##
    # Start the XML parser on the fd
    def start(fd)
      @stream_mechanisms = []
      @stream_features = {}

      @fd = fd
      @parser = StreamParser.new(@fd, self)
      @parserThread = Thread.new do
        begin
          @parser.parse
        rescue Exception => e
          Jabber::debuglog("EXCEPTION:\n#{e.class}\n#{e.message}\n#{e.backtrace.join("\n")}")

          if @exception_block
            Thread.new { close; @exception_block.call(e, self, :start) }
          else
            puts "Exception caught in Parser thread!"
            close
            raise
          end
        end
      end
#      @pollThread = Thread.new do
#        begin
#        poll
#        rescue
#          puts "Exception caught in Poll thread, dumping backtrace and" +
#            " exiting...\n" + $!.exception + "\n"
#          puts $!.backtrace
#          exit
#        end
#      end
      @status = CONNECTED
    end

    def stop
      @parserThread.kill
      @parser = nil
    end

    ##
    # Mounts a block to handle exceptions if they occur during the 
    # poll send.  This will likely be the first indication that
    # the socket dropped in a Jabber Session.
    #
    # The block has to take three arguments:
    # * the Exception
    # * the Jabber::Stream object (self)
    # * a symbol where it happened, namely :start, :parser, :sending and :end
    def on_exception(&block)
      @exception_block = block
    end

    ##
    # This method is called by the parser when a failure occurs
    def parse_failure(e)
      Jabber::debuglog("EXCEPTION:\n#{e.class}\n#{e.message}\n#{e.backtrace.join("\n")}")

      # A new thread has to be created because close will cause the thread
      # to commit suicide(???)
      if @exception_block
        # New thread, because close will kill the current thread
        Thread.new {
          close
          @exception_block.call(e, self, :parser)
        }
      else
        puts "Stream#parse_failure was called by XML parser. Dumping " +
        "backtrace...\n" + e.exception + "\n"
        puts e.backtrace
        close
        raise
      end
    end

    ##
    # This method is called by the parser upon receiving <tt></stream:stream></tt>
    def parser_end
      if @exception_block
        Thread.new {
          close
          @exception_block.call(nil, self, :close)
        }
      else
        close
      end
    end

    ##
    # Returns if this connection is connected to a Jabber service
    # return:: [Boolean] Connection status
    def is_connected?
      return @status == CONNECTED
    end

    ##
    # Returns if this connection is NOT connected to a Jabber service
    #
    # return:: [Boolean] Connection status
    def is_disconnected?
      return @status == DISCONNECTED
    end

    ##
    # Processes a received REXML::Element and executes 
    # registered thread blocks and filters against it.
    #
    # If in threaded mode, a new thread will be spawned
    # for the call to receive_nonthreaded.
    # element:: [REXML::Element] The received element
    def receive(element)
      if @threaded
        # Don't spawn a new thread here. An implicit feature
        # of XMPP is constant order of stanzas.
        receive_nonthreaded(element)
      else
        receive_nonthreaded(element)
      end
    end
    
    def receive_nonthreaded(element)
      Jabber::debuglog("RECEIVED:\n#{element.to_s}")
      case element.prefix
      when 'stream'
        case element.name
          when 'stream'
            stanza = element
            @streamid = element.attributes['id']
            unless element.attributes['version']  # isn't XMPP compliant, so
              Jabber::debuglog("FEATURES: server not XMPP compliant, will not wait for features")
              @features_lock.unlock               # don't wait for <stream:features/>
            end
          when 'features'
            stanza = element
            element.each { |e|
              if e.name == 'mechanisms' and e.namespace == 'urn:ietf:params:xml:ns:xmpp-sasl'
                e.each_element('mechanism') { |mech|
                  @stream_mechanisms.push(mech.text)
                }
              else
                @stream_features[e.name] = e.namespace
              end
            }
            Jabber::debuglog("FEATURES: received")
            @features_lock.unlock
          else
            stanza = element
        end
      else
        case element.name
          when 'message'
            stanza = Message::import(element)
          when 'iq'
            stanza = Iq::import(element)
          when 'presence'
            stanza = Presence::import(element)
          else
            stanza = element
        end
      end

      # Iterate through blocked threads (= waiting for an answer)
      #
      # We're dup'ping the @threadblocks here, so that we won't end up in an
      # endless loop if Stream#send is being nested. That means, the nested
      # threadblock won't receive the stanza currently processed, but the next
      # one.
      threadblocks = @threadblocks.dup
      threadblocks.each { |threadblock|
        exception = nil
        r = false
        begin
          r = threadblock.call(stanza)
        rescue Exception => e
          exception = e
        end

        if r == true
          @threadblocks.delete(threadblock)
          threadblock.wakeup
          return
        elsif exception
          @threadblocks.delete(threadblock)
          threadblock.raise(exception)
        end
      }

      if @threaded
        process_one(stanza)
      else
        # stanzaqueue will be read when the user call process
        @stanzaqueue_lock.lock
        @stanzaqueue.push(stanza)
        @stanzaqueue_lock.unlock
        @waiting_thread.wakeup if @waiting_thread
      end
    end
    private :receive_nonthreaded

    ##
    # Process |element| until it is consumed. Returns element.consumed?
    # element  The element to process
    def process_one(stanza)
      Jabber::debuglog("PROCESSING:\n#{stanza.to_s}")
      return true if @xmlcbs.process(stanza)
      return true if @stanzacbs.process(stanza)
      case stanza
      when Message
        return true if @messagecbs.process(stanza)
      when Iq
        return true if @iqcbs.process(stanza)
      when Presence
        return true if @presencecbs.process(stanza)
      end
    end
    private :process_one

    ##
    # Process |max| XML stanzas and call listeners for all of them. 
    #
    # max:: [Integer] the number of stanzas to process (nil means process
    # all available)
    def process(max = nil)
      n = 0
      @stanzaqueue_lock.lock
      while @stanzaqueue.size > 0 and (max == nil or n < max)
        e = @stanzaqueue.shift
        @stanzaqueue_lock.unlock
        process_one(e)
        n += 1
        @stanzaqueue_lock.lock
      end
      @stanzaqueue_lock.unlock
      n
    end

    ##
    # Process an XML stanza and call the listeners for it. If no stanza is
    # currently available, wait for max |time| seconds before returning.
    # 
    # time:: [Integer] time to wait in seconds. If nil, wait infinitely.
    # all available)
    def wait_and_process(time = nil)
      if time == 0 
        return process(1)
      end
      @stanzaqueue_lock.lock
      if @stanzaqueue.size > 0
        e = @stanzaqueue.shift
        @stanzaqueue_lock.unlock
        process_one(e)
        return 1
      end

      @waiting_thread = Thread.current
      @wakeup_thread = Thread.new { sleep time ; @waiting_thread.wakeup if @waiting_thread }
      @waiting_thread.stop
      @wakeup_thread.kill if @wakeup_thread
      @wakeup_thread = nil
      @waiting_thread = nil

      @stanzaqueue_lock.lock
      if @stanzaqueue.size > 0
        e = @stanzaqueue.shift
        @stanzaqueue_lock.unlock
        process_one(e)
        return 1
      end
      return 0
    end

    ##
    # This is used by Jabber::Stream internally to
    # keep track of any blocks which were passed to
    # Stream#send.
    class ThreadBlock
      def initialize(block)
        @thread = Thread.current
        @block = block
      end
      def call(*args)
        @block.call(*args)
      end
      def wakeup
        # TODO: Handle threadblock removal if !alive?
        @thread.wakeup if @thread.alive?
      end
      def raise(exception)
        @thread.raise(exception) if @thread.alive?
      end
    end

    ##
    # Sends XML data to the socket and (optionally) waits
    # to process received data.
    #
    # xml:: [String] The xml data to send
    # &block:: [Block] The optional block
    def send(xml, &block)
      Jabber::debuglog("SENDING:\n#{xml}")
      @threadblocks.unshift(ThreadBlock.new(block)) if block
      Thread.critical = true # we don't want to be interupted before we stop!
      begin
        @fd << xml.to_s
        @fd.flush
      rescue Exception => e
        Jabber::debuglog("EXCEPTION:\n#{e.class}\n#{e.message}\n#{e.backtrace.join("\n")}")

        if @exception_block 
          Thread.new { close!; @exception_block.call(e, self, :sending) }
        else
          puts "Exception caught while sending!"
          close!
          raise
        end
      end
      Thread.critical = false
      # The parser thread might be running this (think of a callback running send())
      # If this is the case, we mustn't stop (or we would cause a deadlock)
      Thread.stop if block and Thread.current != @parserThread
      @pollCounter = 10
    end

    ##
    # Send an XMMP stanza with an Jabber::XMLStanza#id. The id will be
    # generated by Jabber::IdGenerator if not already set.
    #
    # The block will be called once: when receiving a stanza with the
    # same Jabber::XMLStanza#id. It *must* return true to complete this!
    #
    # Be aware that if a stanza with <tt>type='error'</tt> is received
    # the function does not yield but raises an ErrorException with
    # the corresponding error element.
    #
    # Please read the note about nesting at Stream#send
    # xml:: [XMLStanza]
    def send_with_id(xml, &block)
      if xml.id.nil?
        xml.id = Jabber::IdGenerator.instance.generate_id
      end

      error = nil
      send(xml) do |received|
        if received.kind_of? XMLStanza and received.id == xml.id
          if received.type == :error
            error = (received.error ? received.error : Error.new)
            true
          else
            yield(received)
          end
        else
          false
        end
      end

      unless error.nil?
        raise ErrorException.new(error)
      end
    end

    ##
    # Starts a polling thread to send "keep alive" data to prevent
    # the Jabber connection from closing for inactivity.
    #
    # Currently not working!
    def poll
      sleep 10
      while true
        sleep 2
#        @pollCounter = @pollCounter - 1
#        if @pollCounter < 0
#          begin
#            send("  \t  ")
#          rescue
#            Thread.new {@exception_block.call if @exception_block}
#            break
#          end
#        end
      end
    end

    ##
    # Adds a callback block to process received XML messages
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # &block:: [Block] The optional block
    def add_xml_callback(priority = 0, ref = nil, &block)
      @xmlcbs.add(priority, ref, block)
    end

    ##
    # Delete an XML-messages callback
    #
    # ref:: [String] The reference of the callback to delete
    def delete_xml_callback(ref)
      @xmlcbs.delete(ref)
    end

    ##
    # Adds a callback block to process received Messages
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # &block:: [Block] The optional block
    def add_message_callback(priority = 0, ref = nil, &block)
      @messagecbs.add(priority, ref, block)
    end

    ##
    # Delete an Message callback
    #
    # ref:: [String] The reference of the callback to delete
    def delete_message_callback(ref)
      @messagecbs.delete(ref)
    end

    ##
    # Adds a callback block to process received Stanzas
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # &block:: [Block] The optional block
    def add_stanza_callback(priority = 0, ref = nil, &block)
      @stanzacbs.add(priority, ref, block)
    end

    ##
    # Delete a Stanza callback
    #
    # ref:: [String] The reference of the callback to delete
    def delete_stanza_callback(ref)
      @stanzacbs.delete(ref)
    end
    
    ##
    # Adds a callback block to process received Presences 
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # &block:: [Block] The optional block
    def add_presence_callback(priority = 0, ref = nil, &block)
      @presencecbs.add(priority, ref, block)
    end

    ##
    # Delete a Presence callback
    #
    # ref:: [String] The reference of the callback to delete
    def delete_presence_callback(ref)
      @presencecbs.delete(ref)
    end
    
    ##
    # Adds a callback block to process received Iqs
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # &block:: [Block] The optional block
    def add_iq_callback(priority = 0, ref = nil, &block)
      @iqcbs.add(priority, ref, block)
    end

    ##
    # Delete an Iq callback
    #
    # ref:: [String] The reference of the callback to delete
    #
    def delete_iq_callback(ref)
      @iqcbs.delete(ref)
    end
    ##
    # Closes the connection to the Jabber service
    def close
      close!
    end

    def close!
      @parserThread.kill if @parserThread
#      @pollThread.kill
      @fd.close if @fd and !@fd.closed?
      @status = DISCONNECTED
    end
  end
end

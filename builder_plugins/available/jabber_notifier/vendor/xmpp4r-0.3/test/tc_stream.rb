#!/usr/bin/ruby

$:.unshift '../lib'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r/stream'
include Jabber


class StreamTest < Test::Unit::TestCase
  def setup
    @tmpfile = Tempfile::new("StreamSendTest")
    @tmpfilepath = @tmpfile.path()
    @tmpfile.unlink
    @servlisten = UNIXServer::new(@tmpfilepath)
    @server = nil
    thServer = Thread.new { @server = @servlisten.accept }
    @iostream = UNIXSocket::new(@tmpfilepath)
    n = 0
    while @server.nil? and n < 10
      sleep 0.1
      n += 1
    end
    @stream = Stream::new(false)
    @stream.start(@iostream)
  end

  def teardown
    @stream.close
    @server.close
  end

  ##
  # tests that stream really waits the call to process() to dispatch
  # stanzas to filters
  def test_process
=begin
Disabled, because non-threaded mode is broken

    called = false
    @stream.add_xml_callback { called = true }
    assert(!called)
    @server.puts('<stream:stream>')
    @server.flush
    sleep 0.1
    assert(!called)
    @stream.process
    assert(called)
=end
  end

  ##
  # tests that you can select how many messages you want to get with process
  def test_process_multi
=begin
Disabled, because non-threaded mode is broken

    nbcalls = 0
    called = false
    @stream.add_xml_callback { |element|
      nbcalls += 1
      if element.name == "message"
        called = true
      end
    }
    assert(!called)
    @server.puts('<stream:stream/>')
    @server.flush
    assert(!called)
    @stream.process
    assert(!called)
    assert_equal(1, nbcalls)
    for i in 1..10
      @server.puts('<presence/>')
      @server.flush
    end
    @server.puts('<message/>')
    @server.flush
    assert(!called)
    assert_equal(1, nbcalls)
    @stream.process(8)
    assert_equal(9, nbcalls)
    assert(!called)
    @stream.process(2)
    assert_equal(11, nbcalls)
    assert(!called)
    @stream.process(1)
    assert_equal(12, nbcalls)
    assert(called)
=end
  end

  # tests that you can get all waiting messages if you don't use a parameter
  def test_process_multi2
=begin
Disabled, because non-threaded mode is broken

    @called = false
    @nbcalls = 0
    @stream.add_xml_callback { |element|
      @nbcalls += 1
      if element.name == "message"
        @called = true
      end
    }
    assert(!@called)
    @server.puts('<stream:stream>')
    @server.flush
    assert(!@called)
    @stream.process
    assert(!@called)
    assert_equal(1, @nbcalls)
    for i in 1..20
      @server.puts('<iq/>')
      @server.flush
    end
    @server.puts('<message/>')
    @server.flush
    assert(!@called)
    assert_equal(1, @nbcalls)
    @stream.process
    assert_equal(22, @nbcalls)
    assert(@called)
=end
  end

  # Check that <message><message/></message> is recognized as one Message
  def test_similar_children
    n = 0
    @stream.add_message_callback { n += 1 }
    assert_equal(0, n)
    @server.puts('<stream:stream><message/>')
    @server.flush
    @stream.process
    assert_equal(1, n)
    @server.puts('<message>')
    @server.flush
    @stream.process
    assert_equal(1, n)
    @server.puts('<message/>')
    @server.flush
    @stream.process
    assert_equal(1, n)
    @server.puts('</message>')
    @server.flush
    @stream.process
    assert_equal(2, n)
    @server.puts('<message><stream:stream><message/></stream:stream>')
    @server.flush
    @stream.process
    assert_equal(2, n)
    @server.puts('</message>')
    @server.flush
    @stream.process
    assert_equal(3, n)
  end

  def test_send
    @server.puts('<stream:stream>')
    @server.flush
    @stream.process

    Thread.new {
      assert_equal(Iq.new(:get).to_s, @server.gets('>'))
      @stream.receive(Iq.new(:result))
    }

    called = 0
    @stream.send(Iq.new(:get)) { |reply|
      called += 1
      if reply.kind_of? Iq and reply.type == :result
        true
      else
        false
      end
    }

    assert_equal(1, called)
  end
end

#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/client'
include Jabber

class ConnectionErrorTest < Test::Unit::TestCase
  def test_connectionError_start_withexcblock
    @conn, @server = IO.pipe
    @stream = Stream::new(false)
    error = false
    @stream.on_exception do |e, o, w|
      assert_equal(RuntimeError, e.class)
      assert_equal(Jabber::Stream, o.class)
      assert_equal(:start, w)
      error = true
    end
    assert(!error)
    @stream.start(nil)
    sleep 0.2
    assert(error)
    @server.close
    @stream.close
  end

  def test_connectionError_parse_withexcblock
    @conn, @server = IO.pipe
    @stream = Stream::new(false)
    error = false
    @stream.start(@conn)
    @stream.on_exception do |e, o, w|
      assert_equal(REXML::ParseException, e.class)
      assert_equal(Jabber::Stream, o.class)
      assert_equal(:parser, w)
      error = true
    end
    @server.puts('<stream:stream>')
    @server.flush
    assert(!error)
    assert_raise(Errno::EPIPE) {
      @server.puts('</blop>')
    }
    @server.flush
    sleep 0.2
    assert(error)
    @server.close
    @stream.close
  end

  def test_connectionError_send_withexcblock
    @conn, @server = IO.pipe
    @stream = Stream::new(false)
    error = false
    @stream.start(@conn)
    @stream.on_exception do |e, o, w|
      assert_equal(IOError, e.class)
      assert_equal(Jabber::Stream, o.class)
      assert_equal(:sending, w)
      error = true
    end
    @server.puts('<stream:stream>')
    @server.flush
    assert(!error)
    @stream.send('</test>')
    sleep 0.2
    assert(error)
    @server.close
    @stream.close
  end

  def test_connectionError_send_withoutexcblock
    @conn, @server = IO.pipe
    @stream = Stream::new(false)
    @stream.start(@conn)
    @server.puts('<stream:stream>')
    @server.flush
    assert_raise(IOError) { @stream.send('</test>') }
    @server.close
    @stream.close
  end



end

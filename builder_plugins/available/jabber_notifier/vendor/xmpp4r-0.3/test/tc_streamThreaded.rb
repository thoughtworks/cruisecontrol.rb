#!/usr/bin/ruby

$:.unshift '../lib'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r/stream'
include Jabber

class StreamThreadedTest < Test::Unit::TestCase
  def setup
    @tmpfile = Tempfile::new("StreamSendTest")
    @tmpfilepath = @tmpfile.path()
    @tmpfile.unlink
    @servlisten = UNIXServer::new(@tmpfilepath)
    thServer = Thread.new { @server = @servlisten.accept }
    @iostream = UNIXSocket::new(@tmpfilepath)
    n = 0
    while not defined? @server and n < 10
      sleep 0.1
      n += 1
    end
    @stream = Stream::new
    @stream.start(@iostream)
  end

  def teardown
    @stream.close
    @server.close
  end

  ##
  # tests that connection really waits the call to process() to dispatch
  # stanzas to filters
  def test_process
    called = false
    @stream.add_xml_callback { called = true }
    assert(!called)
    @server.puts('<stream:stream>')
    @server.flush
    assert(called)
  end

  def test_process100
    @server.puts('<stream:stream>')
    @server.flush

    n = 0
    @stream.add_message_callback { n += 1 }

    100.times {
      @server.puts('<message/>')
      @server.flush
    }

    assert_equal(100, n)

    @server.puts('<message/>' * 100)
    @server.flush
    sleep 0.1

    assert_equal(200, n)
  end

  def test_send
    @server.puts('<stream:stream>')
    @server.flush

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

  def test_send_nested
    @server.puts('<stream:stream>')
    @server.flush
    finished = Mutex.new
    finished.lock

    Thread.new {
      assert_equal(Iq.new(:get).to_s, @server.gets('>'))
      @server.puts(Iq.new(:result).set_id('1').to_s)
      @server.flush
      assert_equal(Iq.new(:set).to_s, @server.gets('>'))
      @server.puts(Iq.new(:result).set_id('2').to_s)
      @server.flush
      assert_equal(Iq.new(:get).to_s, @server.gets('>'))
      @server.puts(Iq.new(:result).set_id('3').to_s)
      @server.flush

      finished.unlock
    }

    called_outer = 0
    called_inner = 0

    @stream.send(Iq.new(:get)) { |reply|
      called_outer += 1
      assert_kind_of(Iq, reply)
      assert_equal(:result, reply.type)
      
      if reply.id == '1'
        @stream.send(Iq.new(:set)) { |reply|
          called_inner += 1
          assert_kind_of(Iq, reply)
          assert_equal(:result, reply.type)
          assert_equal('2', reply.id)

          @stream.send(Iq.new(:get))

          true
        }
        false
      elsif reply.id == '3'
        true
      else
        false
      end
    }

    assert_equal(2, called_outer)
    assert_equal(1, called_inner)

    finished.lock
  end

  def test_bidi
    @server.puts('<stream:stream>')
    @server.flush
    finished = Mutex.new
    ok = true

    Thread.new {
      100.times { |i|
        ok &&= (Iq.new(:get).set_id(i).to_s == @server.gets('>'))
        @server.puts(Iq.new(:result).set_id(i).to_s)
        @server.flush
      }
      finished.unlock
    }

    100.times { |i|
      @stream.send(Iq.new(:get).set_id(i)) { |reply|
        ok &&= reply.kind_of? Iq
        ok &&= (:result == reply.type)
        ok &&= (i.to_s == reply.id)
        true
      }
    }

    assert(ok)
    2.times { finished.lock }
  end
end

#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/bytestreams'
include Jabber

class SOCKS5BytestreamsTest < Test::Unit::TestCase
  include ClientTester

  @@server = Bytestreams::SOCKS5BytestreamsServer.new(65005)
  @@server.add_address('localhost')

  def create_buffer(size)
    ([nil] * size).collect { rand(256).chr }.join
  end

  def test_pingpong
    target = Bytestreams::SOCKS5BytestreamsTarget.new(@server, '1', '1@a.com/1', '1@a.com/2')
    initiator = Bytestreams::SOCKS5BytestreamsInitiator.new(@client, '1', '1@a.com/1', '1@a.com/2')
    initiator.add_streamhost(@@server)


    Thread.new do
      target.accept

      while buf = target.read(256)
        target.write(buf)
        target.flush
      end

      target.close
    end


    initiator.open

    10.times do
      buf = create_buffer(8192)
      initiator.write(buf)
      initiator.flush

      bufr = ''
      begin
        bufr += initiator.read(256)
      end while bufr.size < buf.size
      assert_equal(buf, bufr)
    end

    initiator.close
  end
  
end

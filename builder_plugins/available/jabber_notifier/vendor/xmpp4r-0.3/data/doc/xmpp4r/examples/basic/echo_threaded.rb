#!/usr/bin/ruby

# This bot will reply to every message it receives. To end the game, send 'exit'
# THREADED VERSION

require 'xmpp4r/client'
include Jabber

# settings
if ARGV.length != 2
  puts "Run with ./echo_thread.rb user@server/resource password"
  exit 1
end
myJID = JID::new(ARGV[0])
myPassword = ARGV[1] 
cl = Client::new(myJID)
cl.connect
cl.auth(myPassword)
cl.send(Presence::new)
puts "Connected ! send messages to #{myJID.strip.to_s}."
mainthread = Thread.current
cl.add_message_callback do |m|
  if m.type != :error
    cl.send(Message::new(m.from, "You sent: #{m.body}"))
    if m.body == 'exit'
      cl.send(Message::new(m.from, "Exiting ..."))
      mainthread.wakeup
    end
  end
end
Thread.stop
cl.close

#!/usr/bin/ruby

# This bot will reply to every message it receives. To end the game, send 'exit'
# NON-THREADED VERSION

require 'xmpp4r'
include Jabber

# settings
if ARGV.length != 2
  puts "Run with ./echo_thread.rb user@server/resource password"
  exit 1
end
myJID = JID::new(ARGV[0])
myPassword = ARGV[1] 
cl = Client::new(myJID, false)
cl.connect
cl.auth(myPassword)
cl.send(Presence::new)
puts "Connected ! send messages to #{myJID.strip.to_s}."
exit = false
cl.add_message_callback { |m|
  cl.send(Message::new(m.from, "You sent: #{m.body}"))
  if m.body == 'exit'
    cl.send(Message::new(m.from, "Exiting ..."))
    exit = true
  end
}
while not exit
  cl.process
end
cl.close

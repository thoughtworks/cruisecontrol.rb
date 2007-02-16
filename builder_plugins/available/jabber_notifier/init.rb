$LOAD_PATH << File.join(File.dirname(__FILE__), 'vendor','xmpp4r-0.3','lib')
$LOAD_PATH << File.dirname(__FILE__)

require 'xmpp4r'
require 'jabber_notifier'

Project.plugin :jabber_notifier
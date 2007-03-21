$LOAD_PATH << File.join(File.dirname(__FILE__), 'vendor', 'ruby-growl-1.0.1', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

require 'ruby-growl'
require 'growl_notifier'

Project.plugin :growl_notifier

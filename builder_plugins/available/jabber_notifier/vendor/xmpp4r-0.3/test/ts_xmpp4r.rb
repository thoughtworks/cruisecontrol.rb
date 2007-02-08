#!/usr/bin/ruby -w


$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'test')
$:.unshift File.join(File.dirname(__FILE__), 'lib')
$:.unshift File.join(File.dirname(__FILE__), 'test')

require 'tc_streamThreaded'
require 'bytestreams/tc_ibb'
require 'bytestreams/tc_socks5bytestreams'
require 'delay/tc_xdelay'
require 'muc/tc_muc_simplemucclient'
require 'muc/tc_muc_mucclient'
require 'tc_error'
require 'tc_stream'
require 'tc_idgenerator'
require 'tc_iqquery'
#require 'tc_streamError'
require 'tc_presence'
require 'vcard/tc_iqvcard'
require 'roster/tc_iqqueryroster'
require 'roster/tc_xroster'
require 'roster/tc_helper'
require 'version/tc_iqqueryversion'
require 'version/tc_helper'
require 'tc_streamSend'
require 'tc_jid'
require 'tc_iq'
require 'tc_client'
require 'tc_callbacks'
require 'tc_xmlstanza'
require 'tc_message'
require 'tc_class_names'

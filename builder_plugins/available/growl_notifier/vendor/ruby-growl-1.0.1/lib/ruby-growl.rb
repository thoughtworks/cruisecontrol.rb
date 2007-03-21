#!/usr/local/bin/ruby -w

$TESTING = false unless defined? $TESTING

require 'md5'
require 'socket'

##
# ruby-growl allows you to perform Growl notification via UDP from machines
# without growl installed (for example, non-OSX machines).
# 
# What's Growl?  Growl is a really cool "global notification system for Mac OS
# X".  See http://growl.info/
# 
# You'll need a Mac to recieve Growl notifications, but you can send Growl
# notifications from any UDP-capable machine that runs Ruby.
#
# See also the Ruby Growl bindings in Growl's subversion repository:
# http://growl.info/documentation/growl-source-install.php
# 
# ruby-growl also contains a command-line notification tool named 'growl'.  It
# is almost completely option-compatible with growlnotify.  (All except for -p
# is supported, use --priority instead.)
#
# = Synopsis
#
#   g = Growl.new "127.0.0.1", "ruby-growl",
#                 ["ruby-growl Notification"]
#   g.notify "ruby-growl Notification", "It Came From Ruby-Growl",
#            "Greetings!"

class Growl

  ##
  # The Ruby that ships with Tiger has a broken #pack, so 'v' means network
  # byte order instead of 'n'.

  BROKEN_PACK = [1].pack("n") != "\000\001" # :nodoc:

  ##
  # ruby-growl Version

  VERSION = "1.0.1"

  ##
  # Growl Network Registration Packet +pack+ Format
  #--
  # Format:
  # 
  #   struct GrowlNetworkRegistration {
  #     struct GrowlNetworkPacket {
  #       unsigned char version;
  #       unsigned char type;
  #     } __attribute__((packed));
  #     unsigned short appNameLen;
  #     unsigned char numAllNotifications;
  #     unsigned char numDefaultNotifications;
  #     /*
  #      *  Variable sized. Format:
  #      *  <application name><all notifications><default notifications><checksum>
  #      *  where <all notifications> is of the form (<length><name>){num} and
  #      *  <default notifications> is an array of indices into the all notifications
  #      *  array, each index being 8 bits.
  #      */
  #     unsigned char data[];
  #   } __attribute__((packed));

  GNR_FORMAT = "CCnCCa*"

  GNR_FORMAT.gsub!(/n/, 'v') if BROKEN_PACK

  ##
  # Growl Network Notification Packet +pack+ Format
  #--
  # Format:
  # 
  #   struct GrowlNetworkNotification {
  #     struct GrowlNetworkPacket {
  #       unsigned char version;
  #       unsigned char type;
  #     } __attribute__((packed));
  #     struct GrowlNetworkNotificationFlags {
  #       unsigned reserved: 12;
  #       signed   priority: 3;
  #       unsigned sticky:   1;
  #     } __attribute__((packed)) flags; //size = 16 (12 + 3 + 1)
  #     unsigned short nameLen; 
  #     unsigned short titleLen;
  #     unsigned short descriptionLen;
  #     unsigned short appNameLen;
  #     /*
  #      *  Variable sized. Format:
  #      *  <notification name><title><description><application name><checksum>
  #      */
  #     unsigned char data[];
  #   } __attribute__((packed));

  GNN_FORMAT = "CCnnnnna*"

  GNN_FORMAT.gsub!(/n/, 'v') if BROKEN_PACK

  ##
  # Growl UDP Port

  GROWL_UDP_PORT = 9887

  ##
  # Growl Protocol Version

  GROWL_PROTOCOL_VERSION = 1

  ##
  # Growl Registration Packet Id

  GROWL_TYPE_REGISTRATION = 0

  ##
  # Growl Notification Packet Id

  GROWL_TYPE_NOTIFICATION = 1

  ##
  # Creates a new Growl notifier and automatically registers any notifications
  # with the remote machine.
  #
  # +host+ is the host to contact.
  #
  # +app_name+ is the name of the application sending the notifications.
  #
  # +all_notifies+ is a list of notification types your application sends.
  #
  # +default_notifies+ is a list of notification types that are turned on by
  # default.
  #
  # I'm not sure about what +default_notifies+ is supposed to be set to, since
  # there is a comment that says "not a subset of all_notifies" in the code.
  #
  # +password+ is the password needed to send notifications to +host+.

  def initialize(host, app_name, all_notifies, default_notifies = nil,
                 password = nil)
    @socket = UDPSocket.open
    # FIXME This goes somewhere else
    @socket.connect host, GROWL_UDP_PORT
    @app_name = app_name
    @all_notifies = all_notifies
    @default_notifies = default_notifies.nil? ? all_notifies : default_notifies
    @password = password

    register
  end

  ##
  # Sends a notification.
  #
  # +notify_type+ is the type of notification to send.
  #
  # +title+ is a title for the notification.
  #
  # +message+ is the body of the notification.
  #
  # +priority+ is the priorty of message to send.
  #
  # +sticky+ makes the notification stick until clicked.

  def notify(notify_type, title, message, priority = 0, sticky = false)
    raise "Unknown Notification" unless @all_notifies.include? notify_type
    raise "Invalid Priority" unless priority >= -2 and priority <= 2

    send notification_packet(notify_type, title, message, priority, sticky)
  end

  private unless $TESTING

  ##
  # Registers the notification types with +host+.

  def register
    send registration_packet
  end

  ##
  # Sends a Growl packet

  def send(packet)
    set_sndbuf packet.length
    @socket.send packet, 0
    @socket.flush
  end

  ##
  # Builds a Growl registration packet

  def registration_packet
    length = 0
    data = []
    data_format = ""

    packet = [
      GROWL_PROTOCOL_VERSION,
      GROWL_TYPE_REGISTRATION
    ]

    packet << @app_name.length
    packet << @all_notifies.length
    packet << @default_notifies.length

    data << @app_name
    data_format = "a#{@app_name.length}"

    @all_notifies.each do |notify|
      data << notify.length
      data << notify
      data_format << "na#{notify.length}"
    end

    @default_notifies.each do |notify|
      data << @all_notifies.index(notify) if @all_notifies.include? notify
      data_format << "C"
    end

    data_format.gsub!(/n/, 'v') if BROKEN_PACK

    data = data.pack data_format

    packet << data

    packet = packet.pack GNR_FORMAT

    checksum = MD5.new packet
    checksum.update @password unless @password.nil?

    packet << checksum.digest

    return packet
  end

  ##
  # Builds a Growl notification packet

  def notification_packet(name, title, description, priority, sticky)
    flags = 0
    data = []

    packet = [
      GROWL_PROTOCOL_VERSION,
      GROWL_TYPE_NOTIFICATION,
    ]

    flags = 0
    flags |= ((0x7 & priority) << 1) # 3 bits for priority
    flags |= 1 if sticky # 1 bit for sticky

    packet << flags
    packet << name.length
    packet << title.length
    packet << description.length
    packet << @app_name.length

    data << name
    data << title
    data << description
    data << @app_name

    packet << data.join
    packet = packet.pack GNN_FORMAT

    checksum = MD5.new packet
    checksum.update @password unless @password.nil?

    packet << checksum.digest

    return packet
  end

  ##
  # Set the size of the send buffer
  #--
  # Is this truly necessary?

  def set_sndbuf(length)
    @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDBUF, length
  end

end


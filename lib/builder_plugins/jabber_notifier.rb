require 'xmpp4r'
require 'xmpp4r/roster'
 
class JabberNotifier
  attr_accessor :subscribers, :account, :password
 
  def initialize(project = nil)
    @subscribers = []
    @account = ''
    @password = ''
  end
 
  def connect
    CruiseControl::Log.debug("Jabber notifier: connecting to #{@account}")
    @client = Jabber::Client.new(@account)
    @client.connect
    CruiseControl::Log.debug("Jabber notifier: authenticating")
    @client.auth(@password)
  end
 
  def disconnect
    CruiseControl::Log.debug("Jabber notifier: disconnecting from #{@account}")
    @client.close if @client.respond_to?(:is_connected?) && @client.is_connected?
  end
 
  def reconnect
    disconnect
    connect
  end
 
  def connected?
    @client.respond_to?(:is_connected?) && @client.is_connected?
  end
 
  def build_finished(build)
    if build.failed? || (build.successful? && build.coverage_status_changed?)
      notify_of_build_outcome(build)
    end
  end
 
  def build_fixed(fixed_build, previous_build)
    notify_of_build_outcome(fixed_build)
  end
  
  def notify_of_build_outcome(build)
    if @subscribers.empty?
      CruiseControl::Log.debug("Jabber notifier: no subscribers registered")
    else
      status = build.failed? ? "broken" : "fixed"
      message = "#{build.project.name} Build #{build.label} - #{status.upcase}"
      if Configuration.dashboard_url
        message += ". See #{build.url}"
      end
      if build.successful?
        message << coverage_delta_text(build.project)
      end
      CruiseControl::Log.debug("Jabber notifier: sending 'build #{status}' notice")
      notify(message)
    end
  end
 
  def notify(message)
    #connect
    begin
      CruiseControl::Log.debug("Jabber notifier: sending notice: '#{message}'")
      @subscribers.each do |subscriber|
        connect
        jid = Jabber::JID::new(subscriber)
        msg = Jabber::Message.new(jid)
        msg.type = :normal
        msg.body = message
        attempts = 0
        CruiseControl::Log.debug("Jabber notifier: sending to #{subscriber}")
        begin
          attempts += 1
          @client.send(msg)
          disconnect
        rescue Errno::EPIPE, IOError => e
          CruiseControl::Log.debug("Jabber notifier: #{e.message}")
          sleep 0.33
          reconnect
          retry unless attempts > 3
          raise
        end
      end
    ensure
      disconnect rescue nil
    end
  end

  def subscribe(subscriber)
    request = Jabber::Presence.new.set_type(:subscribe)
    request.to = subscriber
    @client.send(request)
  end

  def unsubscribe(subscriber)
    request = Jabber::Presence.new.set_type(:unsubscribe)
    request.to = subscriber
    @client.send(request)
    @client.send(request.set_type(:unsubscribed))
  end
  
  private
  
  def coverage_delta_text(project)
    delta = project.last_coverage_delta
    return '' if 0 == delta
    text = delta > 0 ? "Yay! Coverage increased by " : "Boo! Coverage decreased by "
    text << ("%0.1f" % delta)
  end
end

Project.plugin :jabber_notifier
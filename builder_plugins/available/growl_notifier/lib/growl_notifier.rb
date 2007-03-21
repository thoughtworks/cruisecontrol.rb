class GrowlNotifier
  BUILD_FIXED_NOTIFICATION = 'Build Fixed'
  BUILD_BROKEN_NOTIFICATION = 'Build Broken'
  NOTIFICATION_TYPES = [BUILD_FIXED_NOTIFICATION, BUILD_BROKEN_NOTIFICATION]
  APPLICATION_NAME = 'CruiseControl.rb'

  attr_accessor :subscribers

  def initialize(project = nil)
    @subscribers = []
  end
  
  def logger
    CruiseControl::Log
  end

  def build_broken(broken_build, previous_build)
    logger.debug("Growl notifier: sending 'build broken' notice to #{subscribers.join(', ')}")
    message = "#{broken_build.project.name} Build #{broken_build.label} - BROKEN"
    growl_clients.each do |client|
      client.notify(BUILD_BROKEN_NOTIFICATION, APPLICATION_NAME, message)
    end
  end

  def build_fixed(fixed_build, previous_build)
    logger.debug("Growl notifier: sending 'build fixed' notice to #{subscribers.join(', ')}")
    message = "#{fixed_build.project.name} Build #{fixed_build.label} - FIXED"
    growl_clients.each do |client|
      client.notify(BUILD_FIXED_NOTIFICATION, APPLICATION_NAME, message)
    end
  end
  
  def growl_clients
    subscribers.map { |ip| Growl.new(ip, APPLICATION_NAME, NOTIFICATION_TYPES) }
  end

end

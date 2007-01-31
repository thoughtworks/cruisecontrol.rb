class Server
  def initialize(dir = Configuration.builds_directory)
    @config_file = dir + "/server_config.rb"
  end
  
  def save
    File.open(@config_file, 'w') do |file|
      file << "ActionMailer::Base.server_settings = " + ActionMailer::Base.server_settings.inspect
    end
  end

  def load
    Kernel.load @config_file if File.exist? @config_file
  end
end

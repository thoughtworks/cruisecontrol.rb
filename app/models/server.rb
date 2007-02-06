class Server
  def initialize(dir = Configuration.builds_directory)
    @config_file = dir + '/server_config.rb'
  end
  
  def load
    Kernel.load @config_file if File.exist? @config_file
  end

end

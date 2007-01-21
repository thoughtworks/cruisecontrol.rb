class Configuration

  @builds_directory = File.expand_path(File.join(RAILS_ROOT, 'builds'))

  class << self
    attr_accessor :builds_directory
  end

end

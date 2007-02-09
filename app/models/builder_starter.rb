require 'singleton'

class BuilderStarter
  @@startup = true;
  
  def self.run_builders_at_startup=(value)
    @@startup = value
  end

  def self.start_builders
    if @@startup
      Projects.load_all.each do |project|
        begin_builder(project.name)
      end
    end
  end
  
  def self.begin_builder(project_name)
    builder_command = "cruise.cmd build #{project_name}"
        
    unless ruby_platform =~ /mswin32/
      system(builder_command) if fork.nil?
    else
      Thread.new(project_name) do |my_project_name|
        system(builder_command)
      end
    end
  end
  
  private
  
  def self.ruby_platform
    RUBY_PLATFORM
  end
    
end
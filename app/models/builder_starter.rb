require 'singleton'

class BuilderStarter
  @@run_builders_at_startup = true;
  
  def self.run_builders_at_startup=(value)
    @@run_builders_at_startup = value
  end

  def self.start_builders
    if @@run_builders_at_startup
      Projects.load_all.each do |project|
        begin_builder(project.name)
      end
    end
  end
  
  def self.begin_builder(project_name)
    unless ruby_platform =~ /mswin32/
      exec("#{RAILS_ROOT}/cruise build #{project_name}") if fork.nil?
    else
      Thread.new(project_name) do |my_project_name|
        system("cruise.cmd build #{project_name}")
      end
    end
  end
  
  private
  
  def self.ruby_platform
    RUBY_PLATFORM
  end
    
end
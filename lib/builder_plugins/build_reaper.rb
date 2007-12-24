# this plugin will delete builds that are no longer wanted, configure it by setting
#
# Configuration.number_of_builds_to_keep = 20
# 
# in site_config.rb
#
require 'fileutils'

class BuildReaper
  cattr_accessor :number_of_builds_to_keep

  def initialize(project)
    @project = project
  end

  def build_finished(build)
    delete_all_builds_but BuildReaper.number_of_builds_to_keep
  end
  
  def delete_all_builds_but(number)
    @project.builds[0..-(number + 1)].each do |build|
      build.destroy
    end
  end
end

Project.plugin :build_reaper unless BuildReaper.number_of_builds_to_keep.nil?

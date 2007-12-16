#
# this plugin will publish logs from your project into the build directory after a build finishes
# by default, it will publish files it finds that match the pattern 
#
# <pre><code>log/*log</code></pre>
#
# but it can be configured to match any number of patterns like this
# 
# <pre><code>project.log_publisher.globs = ['log/*.log', 'tmp/*']</code></log>
#
require 'fileutils'

class LogPublisher
  attr_accessor :globs
  
  def initialize(project)
    @project = project
    @globs = ["log/*.log"]
  end

  def build_finished(build)
    @globs.each do |glob|
      Dir["#{@project.local_checkout}/#{glob}"].each do |file|
        FileUtils.mv file, build.artifacts_directory
      end
    end
  end
end

Project.plugin :log_publisher


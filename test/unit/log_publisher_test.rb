require File.dirname(__FILE__) + '/../test_helper'

class LogPublisherTest < Test::Unit::TestCase
  include FileSandbox
  
  def test_move_files_from_multiple_globs_into_build_dir
    with_sandbox_project do |sandbox, project|
      build = project.create_build(2)
      
      sandbox.new :file => '/work/log/my.log'
      sandbox.new :file => '/work/log/your.log'

      publisher = LogPublisher.new(project)
      publisher.build_finished(build)
      
      assert file("/build-2/my.log").exists?
      assert file("/build-2/your.log").exists?
      assert !file(sandbox.root + "/work/log/your.log").exists?
    end
  end
  
  def test_configure_globs_should_catch_files
    with_sandbox_project do |sandbox, project|
      build = project.create_build(2)
      
      sandbox.new :file => '/work/log/my.log'
      sandbox.new :file => '/work/foo/bar.log'
      sandbox.new :file => '/work/your.txt'

      publisher = LogPublisher.new(project)
      publisher.globs = ['foo/bar.*', '*.txt']
      publisher.build_finished(build)
      
      assert !file("/build-2/my.log").exists?
      assert file("/build-2/bar.log").exists?
      assert file("/build-2/your.txt").exists?
    end
  end
end

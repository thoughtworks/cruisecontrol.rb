require 'test_helper'

class SequentialBuildLoggerTest < ActiveSupport::TestCase
  include FileSandbox


  context "#build_finished" do
      test "should create build_sequence.log when plugin enabled" do
        with_sandbox_project do |sandbox, project|
          build = project.create_build('abcd')
          
          assert_false SandboxFile.new(sandbox.root + "build_sequence.log").exists?
          
          build_logger = SequentialBuildLogger.new(project)
          build_logger.enabled = true
          build_logger.show_in_artifacts = false
          build_logger.build_finished(build)
          
          assert SandboxFile.new(sandbox.root + "/build_sequence.log").exists?
        end
      end

      test "should not create build_sequence.log when plugin enabled" do
        with_sandbox_project do |sandbox, project|
          build = project.create_build('abcd')
          
          assert_false SandboxFile.new(sandbox.root + "build_sequence.log").exists?
          
          build_logger = SequentialBuildLogger.new(project)
          build_logger.enabled = false
          build_logger.show_in_artifacts = false
          build_logger.build_finished(build)
          
          assert_false SandboxFile.new(sandbox.root + "build_sequence.log").exists?
        end
      end

      test "should not move build_sequence.log when show_in_artifacts set to false" do
        with_sandbox_project do |sandbox, project|
          build = project.create_build('abcd')
          
          assert_false SandboxFile.new(sandbox.root + "build_sequence.log").exists?
          
          build_logger = SequentialBuildLogger.new(project)
          build_logger.enabled = true
          build_logger.show_in_artifacts = false
          build_logger.build_finished(build)
          
          assert SandboxFile.new(sandbox.root + "/build_sequence.log").exists?
          assert_false SandboxFile.new(sandbox.root + "build-abcd/build_sequence/index.html").exists?
        end
      end

      test "should move build_sequence.log when show_in_artifacts set to true" do
        with_sandbox_project do |sandbox, project|
          build = project.create_build('abcd')
          
          assert_false SandboxFile.new(sandbox.root + "build_sequence.log").exists?
          
          build_logger = SequentialBuildLogger.new(project)
          build_logger.enabled = true
          build_logger.show_in_artifacts = true
          build_logger.build_finished(build)
          
          assert SandboxFile.new(sandbox.root + "/build_sequence.log").exists?
          assert SandboxFile.new(sandbox.root + "/build-abcd/build_sequence/index.html").exists?
        end
      end

      test "should not try to move build_sequence.log to artifacts when plugin disabled" do
        with_sandbox_project do |sandbox, project|
          build = project.create_build('abcd')
          
          assert_false SandboxFile.new(sandbox.root + "build_sequence.log").exists?
          
          build_logger = SequentialBuildLogger.new(project)
          build_logger.enabled = false
          build_logger.show_in_artifacts = true
          build_logger.build_finished(build)
          
          assert_false SandboxFile.new(sandbox.root + "/build_sequence.log").exists?
          assert_false SandboxFile.new("build-abcd/build_sequence/index.html").exists?
        end
      end

      test "build_sequence.log should have correct contents" do
        with_sandbox_project do |sandbox, project|
          build = project.create_build('abcd')
          build2 = project.create_build('xyz')
          
          assert_false SandboxFile.new(sandbox.root + "build_sequence.log").exists?
          
          build_logger = SequentialBuildLogger.new(project)
          build_logger.enabled = true
          build_logger.show_in_artifacts = true
          build_logger.build_finished(build)
          build_logger.build_finished(build2)
          
          assert SandboxFile.new(sandbox.root + "/build_sequence.log").exists?
          assert_equal "1:abcd\n2:xyz\n" , SandboxFile.new(sandbox.root + "/build_sequence.log").content
          assert SandboxFile.new(sandbox.root + "/build-abcd/build_sequence/index.html").exists?
          assert SandboxFile.new(sandbox.root + "/build-xyz/build_sequence/index.html").exists?
          build_1_html_content = "<link href=\"tablecloth/tablecloth.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n<script type=\"text/javascript\" src=\"tablecloth/tablecloth.js\"></script>\n\n\n<table cellspacing='0' cellpadding='0'><tr><th>Build No</th><th>Commit No</th></tr><tr><td>1</td><td class = 'failed_build'>abcd</td></tr></table>"
          build_2_html_content = "<link href=\"tablecloth/tablecloth.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n<script type=\"text/javascript\" src=\"tablecloth/tablecloth.js\"></script>\n\n\n<table cellspacing='0' cellpadding='0'><tr><th>Build No</th><th>Commit No</th></tr><tr><td>1</td><td class = 'failed_build'>abcd</td></tr><tr><td>2</td><td class = 'failed_build'>xyz</td></tr></table>"
          assert_equal build_1_html_content , SandboxFile.new(sandbox.root + "/build-abcd/build_sequence/index.html").content
          assert_equal build_2_html_content , SandboxFile.new(sandbox.root + "/build-xyz/build_sequence/index.html").content
        end
      end

    end


end

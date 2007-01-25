require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProjectBlockerTest < Test::Unit::TestCase
  include FileSandbox
  
  def test_block_release
    in_total_sandbox do |sandbox|
      project = Object.new
      project.stubs(:name).returns('foo')
      project.stubs(:path).returns(sandbox.root)

      begin
        ProjectBlocker.block(project)
        
        expected_pid_file = "#{sandbox.root}/builder.pid"
        assert File.file?(expected_pid_file)
        assert_equal false, File.open(expected_pid_file, 'w') { |f| f.flock(File::LOCK_EX | File::LOCK_NB) }
        assert_raises("Already holding a lock on project 'foo'") { ProjectBlocker.block(project) }

        ProjectBlocker.release(project)
  
        assert_equal false, File.exists?(expected_pid_file)
        assert_nothing_raised do 
          File.open(expected_pid_file, 'w') { |f| f.puts 'blah' }
        end
        
        lock = File.open(expected_pid_file, 'w')
        begin
          assert_equal 0, lock.flock(File::LOCK_EX | File::LOCK_NB)
          
          assert_raises(/^Another process (probably another builder) holds a lock on project 'foo'/) do
            ProjectBlocker.block(project)
          end
        ensure
          lock.flock(File::LOCK_UN) rescue nil
          lock.close rescue nil
        end
        
      ensure
        ProjectBlocker.release(project) rescue nil
      end
    end
  end
  
end
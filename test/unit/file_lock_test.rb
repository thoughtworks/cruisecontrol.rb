require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class FileLockTest < Test::Unit::TestCase
  include FileSandbox
  
  def test_lock_and_release
    in_total_sandbox do
      file_name = "./my.lock"
      lock = FileLock.new(file_name, "project 'rude'")
      begin
        lock.lock
        
        assert File.file?(file_name)
        assert_equal false, File.open(file_name, 'w') { |f| f.flock(File::LOCK_EX | File::LOCK_NB) }
        assert_raises("Already holding a lock on project 'rude'") { lock.lock }

        lock.release
        
        assert_equal false, File.exists?(file_name)
        assert_nothing_raised do 
          File.open(file_name, 'w') { |f| f.puts 'blah' }
        end
        
        lock_file = File.open(file_name, 'w')
        begin
          assert_equal 0, lock_file.flock(File::LOCK_EX | File::LOCK_NB)
          
          assert_raises(/^Another process holds a lock on '.\/my.lock'/) do
            lock.lock
          end
        ensure
          lock_file.flock(File::LOCK_UN) rescue nil
          lock_file.close rescue nil
        end
        
      ensure
        lock.release rescue nil
      end
    end
  end
  
  def test_locked?
    in_total_sandbox do
      file_name = "./my.lock"
      lock = FileLock.new(file_name)
      
      assert_false lock.locked?
      
      lock_file = File.open(file_name, 'w')
      begin
        locked = lock_file.flock(File::LOCK_EX | File::LOCK_NB)
        assert locked
        assert lock.locked?
      ensure
        lock_file.flock(File::LOCK_UN | File::LOCK_NB)
        lock_file.close
      end            

      assert_false lock.locked?
    end
  end
  
end
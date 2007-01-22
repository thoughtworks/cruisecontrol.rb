require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + '/../lib/file_sandbox')

class FileSandboxTest < Test::Unit::TestCase
  include FileSandbox

  def test_sandbox_cleans_up_file
    in_sandbox do |sandbox|
      name = sandbox.root + "/a.txt"

      File.open(name, "w") {|f| f << "something"}

      assert File.exist?(name)
    end
    assert !File.exist?(name)
  end

  def test_file_exist
    in_sandbox do |sandbox|
      assert !file('a.txt').exists?
      File.open(sandbox.root + "/a.txt", "w") {|f| f << "something"}
      assert file('a.txt').exist?
    end
  end

  def test_create_file
    in_sandbox do |sandbox|
      assert !file('a.txt').exists?

      sandbox.new :file => 'a.txt'

      assert file('a.txt').exist?
    end
  end
end


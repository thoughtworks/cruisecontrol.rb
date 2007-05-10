require 'date'
require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProjectConfigTrackerTest < Test::Unit::TestCase
  include FileSandbox

  def setup
    @sandbox = Sandbox.new
    @tracker = ProjectConfigTracker.new(@sandbox.root)
  end

  def teardown
    @sandbox.clean_up
  end

  def test_config_modifications_should_return_true_if_local_config_file_is_created
    @sandbox.new :file => 'cruise_config.rb'
    assert @tracker.config_modified?
  end

  def test_config_modifications_should_return_true_if_central_config_file_is_created
    @sandbox.new :file => 'work/cruise_config.rb'
    assert @tracker.config_modified?
  end

  def test_config_modifications_should_return_true_if_central_config_file_is_modified
    @tracker.central_contents = 'bar'
    @sandbox.new :file => 'work/cruise_config.rb', :with_contents => 'foo'
    assert @tracker.config_modified?
  end

  def test_config_modifications_should_return_true_if_local_config_file_is_modified
    @tracker.local_contents = 'bar'
    @sandbox.new :file => 'cruise_config.rb', :with_contents => 'foo'
    assert @tracker.config_modified?
  end

  def test_config_modifications_should_return_false_if_config_files_not_modified
    assert_false @tracker.config_modified?

    @sandbox.new :file => 'cruise_config.rb'
    @sandbox.new :file => 'work/cruise_config.rb'

    assert @tracker.config_modified?

    @tracker.update_contents
    assert_false @tracker.config_modified?
  end

  def test_config_modifications_should_return_true_if_local_config_was_deleted    
    @sandbox.new :file => 'cruise_config.rb'
    @tracker.update_contents
    @sandbox.remove :file => 'cruise_config.rb'
    assert @tracker.config_modified?
  end

  def test_config_modifications_should_return_true_if_central_config_was_deleted
    @sandbox.new :file => 'work/cruise_config.rb'
    @tracker.update_contents
    @sandbox.remove :file => 'work/cruise_config.rb'    
    assert @tracker.config_modified?
  end
end
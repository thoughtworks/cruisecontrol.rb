require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class SuccessfulBuildTriggerTest < Test::Unit::TestCase
  include FileSandbox
  include BuildFactory

  def setup
    setup_sandbox
    
    @triggered_project = create_project('triggered_project')
    @triggering_project = create_project('triggering_project')
    Project.stubs(:new).with('triggering_project').returns(@triggering_project)
  end
  
  def teardown
    teardown_sandbox
  end
  
  def test_constructor_should_remember_last_successful_build_of_triggering_project
    trigger = SuccessfulBuildTrigger.new(@triggered_project, @triggering_project.name)
    assert_nil trigger.last_successful_build
    assert_equal 'triggering_project', trigger.triggering_project_name

    create_build @triggering_project, 1
    trigger = SuccessfulBuildTrigger.new(@triggered_project, @triggering_project.name)
    assert_equal "1", trigger.last_successful_build.label
  end

  def test_build_necessary
    trigger = SuccessfulBuildTrigger.new(@triggered_project, @triggering_project.name)
    assert !trigger.build_necessary?(reasons = [])

    create_build @triggering_project, '1'
    assert trigger.build_necessary?(reasons = [])
    assert_equal '1', trigger.last_successful_build.label 

    assert !trigger.build_necessary?(reasons = [])
    assert_equal '1', trigger.last_successful_build.label

    create_build @triggering_project, '1.1'

    assert trigger.build_necessary?(reasons = [])
    assert_equal '1.1', trigger.last_successful_build.label
  end

  private

  def create_build(project, label, state = :succeed!)
    project.create_build(label).build_status.send(state, 0)
  end
end


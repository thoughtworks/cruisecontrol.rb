require File.dirname(__FILE__) + '/../test_helper'
require 'status_helper'

class TestErrorParserTest < Test::Unit::TestCase  
  def test_should_remap_success_project_status_correctly
    assert_equal "Success", map_project_status_to_ccnet_project_status(:success.to_s)
  end
  
  def test_should_remap_never_built_project_status_correctly
    assert_equal "Unknown", map_project_status_to_ccnet_project_status(:never_built.to_s)
  end
  
  def test_should_remap_failed_project_status_correctly
    assert_equal "Failure", map_project_status_to_ccnet_project_status(:failed.to_s)
  end
  
  def test_should_remap_checking_for_modificiations_build_activity_correctly
    assert_equal "CheckingModifications", map_build_activity_to_ccnet_activity(:checking_for_modifications)
  end
  
  def test_should_remap_building_build_activity_correctly
    assert_equal "Building", map_build_activity_to_ccnet_activity(:building)
  end
  
  def test_should_remap_other_building_activities_to_sleeping
    assert_equal "Sleeping", map_build_activity_to_ccnet_activity(:error)
  end
end
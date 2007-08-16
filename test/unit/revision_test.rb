require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProjectTest < Test::Unit::TestCase

  def test_revision_should_know_how_to_compare_itself
    small = Revision.new(3)
    large = Revision.new(5)
    assert small < large
    assert_false small > large
    assert_equal [small, large], [large, small].sort

    another_small = Revision.new(3)
    assert small == another_small 
    assert small != large
  end
end

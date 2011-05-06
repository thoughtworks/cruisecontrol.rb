require 'test_helper'

module SourceControl
  class Subversion::ProjectTest < ActiveSupport::TestCase

    def test_revision_should_know_how_to_compare_itself
      small = Subversion::Revision.new(3)
      large = Subversion::Revision.new(5)
      assert small < large
      assert_false small > large
      assert_equal [small, large], [large, small].sort

      another_small = Subversion::Revision.new(3)
      assert small == another_small
      assert small != large
    end

  end
end

require File.dirname(__FILE__) + '/../../../test_helper'

module SourceControl
  class Git::RevisionTest < Test::Unit::TestCase
    def test_equality_operator
      r1 = Git::Revision.new('123456', nil, nil)

      assert r1 == r1
      assert r1 == Git::Revision.new('123456', nil, nil)
      assert_false r1 == :foo
      assert_false r1 == Git::Revision.new('654321', nil, nil)

      not_a_git_revision = Object.new
      not_a_git_revision.stubs(:number).returns(r1.number)
      assert_false r1 == not_a_git_revision
    end
    
    def test_should_have_sensible_to_s
      assert_equal("Revision 1234 committed by jeremy",
                   Git::Revision.new("1234", "jeremy", nil).to_s)
      assert_equal("Revision 1234 committed by jeremy on 2000-01-02 03:04:00",
                   Git::Revision.new("1234", "jeremy", Time.parse("2000-01-02 03:04:00")).to_s)
    end
  end
end

require File.dirname(__FILE__) + '/../../../test_helper'

module SourceControl
  class Bazaar::RevisionTest < Test::Unit::TestCase
    def test_equality_operator
      r1 = Bazaar::Revision.new('10')

      assert r1 == r1
      assert r1 == Bazaar::Revision.new('10')
      assert_false r1 == :foo
      assert_false r1 == Bazaar::Revision.new('20')

      not_a_git_revision = Object.new
      not_a_git_revision.stubs(:number).returns(r1.number)
      assert_false r1 == not_a_git_revision
    end

    def test_should_have_sensible_to_s
      assert_equal("Revision 10 committed by jeremy\n",
                   Bazaar::Revision.new('10', "jeremy").to_s)
      assert_equal("Revision 10 committed by jeremy on 2000-01-02 03:04:00\n",
                   Bazaar::Revision.new("10", "jeremy", Time.parse("2000-01-02 03:04:00")).to_s)
    end

    def test_should_convert_to_full_diff_message
      expected_message = %{Revision 10 committed by Scott Tamosunas on 2000-01-02 03:04:00

fixed iphone cruise Rakefile
and another line

  M iphone/Rakefile
  M iphone/ibob/ibob.xcodeproj/pivotal.pbxuser
  M iphone/ibob/ibob.xcodeproj/project.pbxproj
}

      revision = Bazaar::Revision.new("10",
                                      "Scott Tamosunas",
                                      Time.parse("2000-01-02 03:04"),
                                      "fixed iphone cruise Rakefile\nand another line",
                                      [ChangesetEntry.new("M", "iphone/Rakefile"),
                                       ChangesetEntry.new("M", "iphone/ibob/ibob.xcodeproj/pivotal.pbxuser"),
                                       ChangesetEntry.new("M", "iphone/ibob/ibob.xcodeproj/project.pbxproj")])

      assert_equal(expected_message, revision.to_s)
    end

  end
end

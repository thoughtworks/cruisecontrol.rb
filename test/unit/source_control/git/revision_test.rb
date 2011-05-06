require 'test_helper'

module SourceControl
  class Git::RevisionTest < ActiveSupport::TestCase
    def test_equality_operator
      r1 = Git::Revision.new(:number => '123456')

      assert r1 == r1
      assert r1 == Git::Revision.new(:number => '123456')
      assert_false r1 == :foo
      assert_false r1 == Git::Revision.new(:number => '654321')

      not_a_git_revision = Object.new
      not_a_git_revision.stubs(:number).returns(r1.number)
      assert_false r1 == not_a_git_revision
    end
    
    def test_should_have_sensible_to_s
      assert_equal("Revision ...1234 committed by jeremy\n",
                   Git::Revision.new(:number => "1234", :author => "jeremy").to_s)
      assert_equal("Revision ...1234 committed by jeremy on 2000-01-02 03:04:00\n",
                   Git::Revision.new(:number => "1234", :author => "jeremy", :time => Time.parse("2000-01-02 03:04:00")).to_s)
    end
    
    def test_should_convert_to_full_diff_message
      expected_message = %{Revision ...7652 committed by Scott Tamosunas on 2000-01-02 03:04:00

    fixed iphone cruise Rakefile
    and another line

 iphone/Rakefile                            |    2 +-
 iphone/ibob/ibob.xcodeproj/pivotal.pbxuser | 2009 +++-------------------------
 iphone/ibob/ibob.xcodeproj/project.pbxproj |  Bin 26641 -> 26654 bytes
 6 files changed, 273 insertions(+), 1875 deletions(-)
}

      revision = Git::Revision.new(:number => "7652", :author => "Scott Tamosunas", 
                                   :time => Time.parse("2000-01-02 03:04"),
                                   :message => "fixed iphone cruise Rakefile\nand another line",
                                   :changeset => [
                                     "iphone/Rakefile                            |    2 +-",
                                     "iphone/ibob/ibob.xcodeproj/pivotal.pbxuser | 2009 +++-------------------------",
                                     "iphone/ibob/ibob.xcodeproj/project.pbxproj |  Bin 26641 -> 26654 bytes"
                                   ],
                                   :summary => "6 files changed, 273 insertions(+), 1875 deletions(-)")

      assert_equal(expected_message, revision.to_s)
    end
    
    def test_get_files_from_changeset
      revision = Git::Revision.new(:changeset => [
                                     "iphone/Rakefile                            |    2 +-",
                                     "iphone/ibob/ibob.xcodeproj/pivotal.pbxuser | 2009 +++-------------------------",
                                     "iphone/ibob/ibob.xcodeproj/project.pbxproj |  Bin 26641 -> 26654 bytes"
                                   ])
                                   
      assert_equal([
        "iphone/Rakefile",
        "iphone/ibob/ibob.xcodeproj/pivotal.pbxuser",
        "iphone/ibob/ibob.xcodeproj/project.pbxproj"
      ], revision.files)
    end
  end
end

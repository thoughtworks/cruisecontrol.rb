require File.dirname(__FILE__) + '/../../../test_helper'

module SourceControl
  class Git::LogParserTest < Test::Unit::TestCase

SIMPLE_LOG_ENTRY = <<EOF
commit e51d66aa4f708fff1c87eb9afc9c48eaa8d5ffce
tree 913027773a63829c82eeb8b626949436b216c857
parent bb52b2f82fea03b7531496c77db01f9348edbbdb
author Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600
committer Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600

    a comment
EOF

BIGGER_LOG_ENTRY = <<EOF
commit d8f6735bcf7d2aa4a46572109d4e091a5d0e1497
tree 06f8ce9a102edb2ca96bba58f02e710f62af63df
parent 5c881c8da857dee2735349c5a36f1f525a347652
author Scott Tamosunas and Brian Jenkins <bob-development@googlegroups.com> 1224202833 -0700
committer Scott Tamosunas and Brian Jenkins <bob-development@googlegroups.com> 1224202833 -0700

    improved rake cruise messags.

 iphone/Rakefile |    3 ++-
 1 files changed, 2 insertions(+), 1 deletions(-)

commit 5c881c8da857dee2735349c5a36f1f525a347652
tree 1a3bcfaa37a254e84f0956bedfa250e6485ee04c
parent d8120fc9372c95dd521bb77d02396c53019c4996
parent ffebfacce8baee80f9f03a2abeea8cdb9dcc7701
author Scott Tamosunas and Brian Jenkins <bob-development@googlegroups.com> 1224202700 -0700
committer Scott Tamosunas and Brian Jenkins <bob-development@googlegroups.com> 1224202700 -0700

    renamed "Unit Test" target to "UnitTest" for developer sanity.
    fixed iphone cruise Rakefile

 iphone/Rakefile                            |    2 +-
 iphone/ibob/ibob.xcodeproj/pivotal.pbxuser | 2009 +++-------------------------
 iphone/ibob/ibob.xcodeproj/project.pbxproj |  Bin 26641 -> 26654 bytes
 6 files changed, 273 insertions(+), 1875 deletions(-)
EOF

    def test_parse_should_work
      expected_revision = Git::Revision.new(
                              :number => 'e51d66a',
                              :author => 'Alexey Verkhovsky <alexey.verkhovsky@gmail.com>',
                              :time => Time.at(1209921867))
      revisions = Git::LogParser.new.parse(SIMPLE_LOG_ENTRY.split("\n"))
      assert_equal [expected_revision], revisions

      assert_equal expected_revision.number, revisions.first.number
      assert_equal expected_revision.author, revisions.first.author
      assert_equal expected_revision.time, revisions.first.time
    end
    
    def test_should_split_into_separate_revisions
      revisions = Git::LogParser.new.parse(BIGGER_LOG_ENTRY.split("\n"))
      assert_equal 2, revisions.size
      
      revision = revisions[1]
      assert_equal "5c881c8", revision.number
      assert_equal "renamed \"Unit Test\" target to \"UnitTest\" for developer sanity.\nfixed iphone cruise Rakefile",
                   revision.message
      assert_equal ["iphone/Rakefile                            |    2 +-",
                    "iphone/ibob/ibob.xcodeproj/pivotal.pbxuser | 2009 +++-------------------------",
                    "iphone/ibob/ibob.xcodeproj/project.pbxproj |  Bin 26641 -> 26654 bytes"],
                   revision.changeset
      assert_equal "6 files changed, 273 insertions(+), 1875 deletions(-)", revision.summary
    end

    def test_parse_line_should_recognize_author
      parser = Git::LogParser.new
      author, time = parser.send(:read_author_and_time, "author Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600")
      assert_equal 'Alexey Verkhovsky <alexey.verkhovsky@gmail.com>', author
      assert_equal Time.at(1209921867), time
    end
  end
end

require 'test_helper'

module SourceControl
  class Bazaar::LogParserTest < Test::Unit::TestCase

    @@example_log_output_single = <<END
<?xml version="1.0" encoding="UTF-8"?><logs><log><revno>4</revno><committer>Glen Mailer &lt;glen@epigenesys.co.uk&gt;</committer><branch-nick>bzr-epidirs</branch-nick><timestamp>Tue 2010-07-20 16:09:02 +0100</timestamp><message><![CDATA[used full hostname instead of genesys3]]></message><affected-files><modified><file>__init__.py</file></modified></affected-files></log></logs>
END

    @@example_log_output_double = <<END
<?xml version="1.0" encoding="UTF-8"?><logs><log><revno>4</revno><committer>Glen Mailer &lt;glen@epigenesys.co.uk&gt;</committer><branch-nick>bzr-epidirs</branch-nick><timestamp>Tue 2010-07-20 16:09:02 +0100</timestamp><message><![CDATA[used full hostname instead of genesys3]]></message><affected-files><modified><file>__init__.py</file></modified></affected-files></log><log><revno>3</revno><committer>Glen Mailer &lt;glen@epigenesys.co.uk&gt;</committer><branch-nick>bzr-epidirs</branch-nick><timestamp>Tue 2010-07-20 11:33:08 +0100</timestamp><message><![CDATA[new epigenesys paths]]></message><affected-files><modified><file>__init__.py</file></modified></affected-files></log></logs>
END

    def setup
      @parser = Bazaar::LogParser.new
    end

    def test_should_parse_double_changeset
      expected = [
          Bazaar::Revision.new('4',
             "Glen Mailer <glen@epigenesys.co.uk>",
             Time.parse("Tue 2010-07-20 16:09:02 +0100"),
             "used full hostname instead of genesys3",
             [ChangesetEntry.new("M", "__init__.py")]),
          Bazaar::Revision.new('3',
             "Glen Mailer <glen@epigenesys.co.uk>",
             Time.parse("Tue 2010-07-20 11:33:08 +0100"),
             "new epigenesys paths",
             [ChangesetEntry.new("M", "__init__.py")])]

      assert_equal expected, @parser.parse(@@example_log_output_double.split("\n"))
    end

    def test_should_parse_single_changeset
      expected = [Bazaar::Revision.new('4',
             "Glen Mailer <glen@epigenesys.co.uk>",
             Time.parse("Tue 2010-07-20 16:09:02 +0100"),
             "used full hostname instead of genesys3",
             [ChangesetEntry.new("M", "__init__.py")])]
      assert_equal expected, @parser.parse(@@example_log_output_single.split("\n"))
    end

  end

end

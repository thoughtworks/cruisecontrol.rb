require File.dirname(__FILE__) + '/../../../test_helper'
require "date"

module SourceControl
  class Mercurial::LogParserTest < Test::Unit::TestCase

    def setup
      @example_log_output_single = <<END
changeset:   5:c3f57b2b476c
tag:         tip
user:        Marcus Ahnve <marcus@re-mind.se>
date:        Mon Apr 02 16:14:59 2007 +0200
files:       app/models/mercurial.rb test/unit/mercurial_test.rb
description:
moved mercurial back to plugin
END

        @example_tip_output_double = <<END
changeset:   4:865db6698186
user:        Marcus Ahnve <marcus@re-mind.se>
date:        Mon Apr 02 15:42:14 2007 +0200
files:       app/models/mercurial.rb app/models/project.rb
description:
moved mercurial to model


changeset:   3:e3f2e642cb26
user:        Marcus Ahnve <marcus@re-mind.se>
date:        Sun Apr 01 17:22:59 2007 +0200
files:       vcs.txt
description:
mailing list instruction
END

        @parser = Mercurial::LogParser.new

      end

      def test_should_parse_single
        expected = [Revision.new(5,
                                 "Marcus Ahnve",
                                 DateTime.parse("Mon Apr 02 16:14:59 2007 +0200"),
                                 "moved mercurial back to plugin",
                                 [ChangesetEntry.new("", "app/models/mercurial.rb"),
                                 ChangesetEntry.new("", "test/unit/mercurial_test.rb")])]
        assert_equal(expected, @parser.parse_log(@example_log_output_single))
      end


    def test_parse_name
      assert_equal("Marcus Ahnve", @parser.parse_for_name(@example_log_output_single))
    end

    def test_parse_date
      assert_equal(DateTime.parse("Mon Apr 02 16:14:59 2007 +0200"), @parser.parse_for_date(@example_log_output_single))
    end

    def test_message
      assert_equal("moved mercurial back to plugin", @parser.parse_for_message(@example_log_output_single))
    end

    def test_parse_rev_number
      assert_equal(5, @parser.parse_for_rev_number(@example_log_output_single))
    end

    def test_parse_files
      expected = ["app/models/mercurial.rb","test/unit/mercurial_test.rb"]
      assert_equal(expected, @parser.parse_for_files(@example_log_output_single))
    end

    def test_split_multiple_log_entries
            entry1 =<<END
changeset:   4:865db6698186
user:        Marcus Ahnve <marcus@re-mind.se>
date:        Mon Apr 02 15:42:14 2007 +0200
files:       app/models/mercurial.rb app/models/project.rb
description:
moved mercurial to model
END
            entry2 =<<END
changeset:   3:e3f2e642cb26
user:        Marcus Ahnve <marcus@re-mind.se>
date:        Sun Apr 01 17:22:59 2007 +0200
files:       vcs.txt
description:
mailing list instruction
END
            expected=[entry1.strip!,entry2.strip!]
            assert_equal(expected, @parser.split_log(@example_tip_output_double))
    end

  end

end


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

    def test_parse_should_work
      expected_revision = Git::Revision.new
      revisions = Git::LogParser.new.parse(SIMPLE_LOG_ENTRY)
      assert_equal [expected_revision], revisions
    end

  end
end

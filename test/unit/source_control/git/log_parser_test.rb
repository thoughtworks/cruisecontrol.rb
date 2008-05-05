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
      expected_revision = Git::Revision.new(
                              'e51d66aa4f708fff1c87eb9afc9c48eaa8d5ffce',
                              'Alexey Verkhovsky <alexey.verkhovsky@gmail.com>',
                              Time.at(1209921867))
      revisions = Git::LogParser.new.parse(SIMPLE_LOG_ENTRY)
      assert_equal [expected_revision], revisions

      assert_equal expected_revision.number, revisions.first.number
      assert_equal expected_revision.committed_by, revisions.first.committed_by
      assert_equal expected_revision.time, revisions.first.time
    end

    def test_parse_line_should_recognize_commit_id
      parser = Git::LogParser.new
      parser.send(:parse_line, "commit e51d66aa4f708fff1c87eb9afc9c48eaa8d5ffce")
      assert_equal 'e51d66aa4f708fff1c87eb9afc9c48eaa8d5ffce', parser.instance_variable_get(:@id) 
    end

    def test_parse_line_should_recognize_author
      parser = Git::LogParser.new
      parser.send(:parse_line, "author Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600")
      assert_equal 'Alexey Verkhovsky <alexey.verkhovsky@gmail.com>', parser.instance_variable_get(:@author)
      assert_equal Time.at(1209921867), parser.instance_variable_get(:@time)
    end

    def test_commit_message_should_recognize_lines_that_start_with_four_spaces_as_commit_lines
      parser = Git::LogParser.new
      assert_false parser.send(:commit_message?, "parent bb52b2f82fea03b7531496c77db01f9348edbbdb")
      assert parser.send(:commit_message?, "    a comment")
    end

  end
end

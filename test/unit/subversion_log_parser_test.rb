require File.dirname(__FILE__) + '/../test_helper'
require 'revision'
require 'changeset_entry'

class SubversionLogParserTest < Test::Unit::TestCase

SIMPLE_LOG_ENTRY = <<EOF
------------------------------------------------------------------------
r359 | aslak | 2006-05-22 13:23:29 -0600 (Mon, 22 May 2006) | 1 line
Changed paths:
   A /trunk/foo.txt

versioning
------------------------------------------------------------------------
EOF

LOG_ENTRY_WITH_MULTIPLE_ENTRIES = <<EOF
------------------------------------------------------------------------
r359 | aslak | 2006-05-22 13:23:29 -0600 (Mon, 22 May 2006) | 1 line
Changed paths:
   A /trunk/foo.txt
   D /trunk/bar.exe

versioning
------------------------------------------------------------------------
r358 | joe | 2006-05-22 13:20:05 -0600 (Mon, 22 May 2006) | 1 line
Changed paths:
   A /trunk/bar.exe

Added Rakefile for packaging of svn ruby bindings (swig) in prebuilt gems for di
fferent platforms
------------------------------------------------------------------------
EOF

UPDATE_OUTPUT = <<EOF
A    failing_project
D    failing_project\\Rakefile
U*   failing_project\\failing_test.rb
G    failing_project\\revision_label.txt
C B  passing_project\\revision_label.txt
?    foo.txt

Fetching external item into 'vendor\rails'
Updated external to revision 5875.

Updated to revision 46.
EOF

  def test_can_parse_SIMPLE_LOG_ENTRY
    expected_result = [Revision.new(359, 'aslak', DateTime.parse('2006-05-22 13:23:29 -0600'), 'versioning',
                                    [ChangesetEntry.new('A', '/trunk/foo.txt')])]
    assert_equal expected_result, parse_log(SIMPLE_LOG_ENTRY)
  end

  def test_can_parse_LOG_ENTRY_WITH_MULTIPLE_ENTRIES
    expected = [
      Revision.new(359, 'aslak', DateTime.parse('2006-05-22 13:23:29 -0600'), 'versioning',
                   [ChangesetEntry.new('A', '/trunk/foo.txt'), ChangesetEntry.new('D', '/trunk/bar.exe')]),
      Revision.new(358, 'joe',   DateTime.parse('2006-05-22 13:20:05 -0600'),
                   "Added Rakefile for packaging of svn ruby bindings (swig) in prebuilt gems for different platforms",
                   [ChangesetEntry.new('A', '/trunk/bar.exe')])
    ]

    assert_equal expected, parse_log(LOG_ENTRY_WITH_MULTIPLE_ENTRIES)
  end

  def test_can_parse_UPDATE_OUTPUT
    expected_result = [
      ChangesetEntry.new('A  ', 'failing_project'),
      ChangesetEntry.new('D  ', 'failing_project\Rakefile'),
      ChangesetEntry.new('U* ', 'failing_project\\failing_test.rb'),
      ChangesetEntry.new('G  ', 'failing_project\\revision_label.txt'),
      ChangesetEntry.new('C B', 'passing_project\\revision_label.txt'),
      ChangesetEntry.new('?  ', 'foo.txt')]

    assert_equal expected_result, parse_update(UPDATE_OUTPUT)
  end

  def test_revision_and_changeset_should_know_how_to_convert_to_string
    expected_result = <<-EOL
Revision 359 committed by aslak on #{DateTime.parse("2006-05-22 13:23:29 -0600").strftime('%Y-%m-%d %H:%M:%S')}
versioning
  A /trunk/foo.txt
    EOL
    assert_equal expected_result, parse_log(SIMPLE_LOG_ENTRY)[0].to_s
  end

  def parse_log(log_entry)
    SubversionLogParser.new.parse_log(log_entry.split("\n"))
  end

  def parse_update(log_entry)
    SubversionLogParser.new.parse_update(log_entry.split("\n"))
  end

end
require File.dirname(__FILE__) + '/../test_helper'
require 'revision'
require 'changeset_entry'

class SubversionUpdateParserTest < Test::Unit::TestCase

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

  def parse_update(log_entry)
    SubversionUpdateParser.new.parse(log_entry.split("\n"))
  end
end
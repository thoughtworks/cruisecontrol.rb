require File.dirname(__FILE__) + '/../test_helper'
require 'revision'
require 'changeset_entry'

class SubversionLogParserTest < Test::Unit::TestCase
SIMPLE_LOG_ENTRY = <<EOF
<?xml version="1.0"?>
<log>
<logentry revision="359">
  <author>aslak</author>
  <date>2006-05-22T13:23:29.000005Z</date>
  <paths>
    <path action="A">/trunk/foo.txt</path>
  </paths>
  <msg>versioning</msg>
</logentry>
</log>
EOF

LOG_WITH_NO_MESSAGE = <<EOF
<log>
<logentry revision="1">
  <msg></msg>
</logentry>
</log>
EOF

# how do I do this????  I don't know what the xml for this looks like  - jeremy
LOG_ENTRY_WITH_ANONYMOUS_AUTHOR = <<EOF
<log>
<logentry revision="127">
  <author>(no author)</author>
  <date>2006-05-22T13:23:29.000005Z</date>
  <paths>
    <path action="A">/trunk/foo.txt</path>
  </paths>
  <msg>categories added</msg>
</logentry>
</log>
EOF

LOG_ENTRY_WITH_MULTIPLE_ENTRIES = <<EOF
<log>
<logentry revision="359">
  <author>aslak</author>
  <date>2006-05-22T13:23:29.000005Z</date>
  <paths>
    <path action="A">/trunk/foo.txt</path>
    <path action="D">/trunk/bar.exe</path>
  </paths>
  <msg>versioning</msg>
</logentry>
<logentry revision="358">
  <author>joe</author>
  <date>2006-05-22T13:20:05.471105Z</date>
  <paths>
    <path action="A">/trunk/bar.exe</path>
  </paths>
  <msg>Added Rakefile for packaging of svn ruby bindings (swig) in prebuilt gems for different platforms</msg>
</logentry>
</log>
EOF

  def test_can_parse_LOG_WITH_NO_OPTIONAL_VALUES
    expected_result = [Revision.new(359, nil, nil, nil, [])]
                                  
    assert_equal expected_result, parse_log("<log><logentry revision='359'/></log>")
  end

  def test_can_parse_SIMPLE_LOG_ENTRY
    expected_result = [Revision.new(359, 'aslak', DateTime.parse('2006-05-22T13:23:29.000005Z'), 'versioning',
                                    [ChangesetEntry.new('A', '/trunk/foo.txt')])]
    actual = parse_log(SIMPLE_LOG_ENTRY)
                                  
    assert_equal expected_result, actual
    assert_equal "Revision 359 committed by aslak on 2006-05-22 13:23:29\nversioning\n  A /trunk/foo.txt\n", actual.to_s #this is fixing a bug
  end

  def test_can_parse_LOG_WITH_NO_MESSAGE
    expected = [Revision.new(1, nil, nil, nil, [])]
    actual = parse_log(LOG_WITH_NO_MESSAGE)
    
    assert_equal expected, actual
    assert_equal "Revision 1 committed by  on \n\n\n", actual.to_s #this is fixing a bug
  end

  def test_can_parse_LOG_ENTRY_WITH_ANONYMOUS_AUTHOR
    expected_result = [Revision.new(127, '(no author)', DateTime.parse('2006-05-22T13:23:29.000005Z'), 'categories added',
                                    [ChangesetEntry.new('A', '/trunk/foo.txt')])]
    assert_equal expected_result, parse_log(LOG_ENTRY_WITH_ANONYMOUS_AUTHOR)
  end


  def test_can_parse_LOG_ENTRY_WITH_MULTIPLE_ENTRIES
    expected = [
      Revision.new(359, 'aslak', DateTime.parse('2006-05-22T13:23:29.000005Z'), 'versioning',
                   [ChangesetEntry.new('A', '/trunk/foo.txt'), ChangesetEntry.new('D', '/trunk/bar.exe')]),
      Revision.new(358, 'joe',   DateTime.parse('2006-05-22T13:20:05.471105Z'),
                   "Added Rakefile for packaging of svn ruby bindings (swig) in prebuilt gems for different platforms",
                   [ChangesetEntry.new('A', '/trunk/bar.exe')])
    ]

    assert_equal expected, parse_log(LOG_ENTRY_WITH_MULTIPLE_ENTRIES)
  end

  def test_DV
    parse_log(LOG_ENTRY_WITH_MULTIPLE_ENTRIES)
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
    SubversionLogParser.new.parse(log_entry.split("\n"))
  end

end
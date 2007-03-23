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

  def test_can_parse_LOG_WITH_NO_OPTIONAL_VALUES
    expected_result = [Revision.new(359, nil, nil, nil, [])]
                                  
    assert_equal expected_result, parse_log("<log><logentry revision='359'/></log>")
  end

  def test_can_parse_SIMPLE_LOG_ENTRY
    expected_result = [Revision.new(359, 'aslak', DateTime.parse('2006-05-22T13:23:29.000005Z'), 'versioning',
                                    [ChangesetEntry.new('A', '/trunk/foo.txt')])]
                                  
    assert_equal expected_result, parse_log(SIMPLE_LOG_ENTRY)
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

INFO_XML_OUTPUT = <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<info>
<entry
   kind="dir"
   path="cruisecontrolrb"
   revision="328">
<url>svn://rubyforge.org/var/svn/cruisecontrolrb</url>
<repository>
<root>svn://rubyforge.org/var/svn/cruisecontrolrb</root>
<uuid>c04ce798-636b-4ca8-9149-0f9336831111</uuid>
</repository>
<commit
   revision="328">
<author>stellsmi</author>
<date>2007-03-08T02:00:09.035499Z</date>
</commit>
</entry>
</info>
EOF

INFO_XML_OUTPUT_WITH_WORKING_COPY = <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<info>
<entry
   kind="file"
   path="README"
   revision="328">
<url>svn://rubyforge.org/var/svn/cruisecontrolrb/README</url>
<repository>
<root>svn://rubyforge.org/var/svn/cruisecontrolrb</root>
<uuid>c04ce798-636b-4ca8-9149-0f9336831111</uuid>
</repository>
<wc-info>
<schedule>add</schedule>
<copy-from-url>svn://rubyforge.org/var/svn/cruisecontrolrb/README</copy-from-url>
<copy-from-rev>99</copy-from-rev>
<text-updated>2007-03-10T03:35:34.000000Z</text-updated>
<prop-updated>2007-03-10T03:35:34.000000Z</prop-updated>
<checksum>d41d8cd98f00b204e9800998ecf8427e</checksum>
</wc-info>
<commit
   revision="328">
<author>stellsmi</author>
<date>2007-03-08T02:00:09.035499Z</date>
</commit>
</entry>
</info>
EOF

INFO_XML_OUTPUT_WITH_LOCK = <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<info>
<entry
   kind="dir"
   path="cruisecontrolrb"
   revision="328">
<url>svn://rubyforge.org/var/svn/cruisecontrolrb</url>
<repository>
<root>svn://rubyforge.org/var/svn/cruisecontrolrb</root>
<uuid>c04ce798-636b-4ca8-9149-0f9336831111</uuid>
</repository>
<commit
   revision="328">
<author>stellsmi</author>
<date>2007-03-08T02:00:09.035499Z</date>
</commit>
<lock>
<token>opaquelocktoken:fc2b4dee-98f9-0310-abf3-653ff3226e6b</token>
<owner>dtsato</owner>
<comment>Dummy comment</comment>
<created>2007-03-08T16:29:18.035499Z</created>
<expires>2007-03-09T16:29:18.035499Z</expires>
</lock>
</entry>
</info>
EOF

INFO_XML_OUTPUT_WITH_CONFLICT = <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<info>
<entry
   kind="file"
   path="README"
   revision="328">
<url>svn://rubyforge.org/var/svn/cruisecontrolrb/README</url>
<repository>
<root>svn://rubyforge.org/var/svn/cruisecontrolrb</root>
<uuid>c04ce798-636b-4ca8-9149-0f9336831111</uuid>
</repository>
<wc-info>
<schedule>replace</schedule>
<text-updated>2007-03-10T03:35:34.000000Z</text-updated>
<prop-updated>2007-03-10T03:35:34.000000Z</prop-updated>
<checksum>d41d8cd98f00b204e9800998ecf8427e</checksum>
</wc-info>
<commit
   revision="328">
<author>stellsmi</author>
<date>2007-03-08T02:00:09.035499Z</date>
</commit>
<conflict>
<prev-base-file>README_base</prev-base-file>
<prev-wc-file>README_wc</prev-wc-file>
<cur-base-file>README_file</cur-base-file>
<prop-file>README_prop</prop-file>
</conflict>
</entry>
</info>
EOF

  def test_should_parse_INFO_XML_OUTPUT
    expected_result = {:revision => 328,
                       :last_changed_revision => 328,
                       :last_changed_author => 'stellsmi'}
    
    assert_info_equal expected_result, parse_info(INFO_XML_OUTPUT)
  end
    
  def test_should_parse_INFO_XML_OUTPUT_WITH_WORKING_COPY
    expected_result = {:revision => 328,
                       :last_changed_revision => 328,
                       :last_changed_author => 'stellsmi'}
    
    assert_info_equal expected_result, parse_info(INFO_XML_OUTPUT_WITH_WORKING_COPY)
  end

  def test_should_parse_INFO_XML_OUTPUT_WITH_LOCK
    expected_result = {:revision => 328,
                       :last_changed_revision => 328,
                       :last_changed_author => 'stellsmi'}
    
    assert_info_equal expected_result, parse_info(INFO_XML_OUTPUT_WITH_LOCK)
  end
  
  def test_should_parse_INFO_XML_OUTPUT_WITH_CONFLICT
    expected_result = {:revision => 328,
                       :last_changed_revision => 328,
                       :last_changed_author => 'stellsmi'}
    
    assert_info_equal expected_result, parse_info(INFO_XML_OUTPUT_WITH_CONFLICT)
  end

  def parse_log(log_entry)
    SubversionLogParser.new.parse_log(log_entry.split("\n"))
  end

  def parse_update(log_entry)
    SubversionLogParser.new.parse_update(log_entry.split("\n"))
  end

  def parse_info(svn_output)
    SubversionLogParser.new.parse_info(svn_output)
  end
  
  def assert_info_equal(expected_fields, info)
    expected_fields.each do |name, value|
      assert_equal value, info.send(name), "comparing #{name}"
    end
  end
end
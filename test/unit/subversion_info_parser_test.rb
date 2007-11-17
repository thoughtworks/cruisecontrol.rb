require File.dirname(__FILE__) + '/../test_helper'
require 'revision'
require 'changeset_entry'

class SubversionInfoParserTest < Test::Unit::TestCase

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

  def parse_info(svn_output)
    SubversionInfoParser.new.parse(svn_output)
  end

  def assert_info_equal(expected_fields, info)
    expected_fields.each do |name, value|
      assert_equal value, info.send(name), "comparing #{name}"
    end
  end
end
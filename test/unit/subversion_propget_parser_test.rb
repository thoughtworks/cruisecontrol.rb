require File.dirname(__FILE__) + '/../test_helper'
require 'revision'
require 'changeset_entry'

class SubversionLogParserTest < Test::Unit::TestCase

PROPGET_ENTRY = <<-EOF
public/javascripts - js-common https://svn.pivotallabs.com/subversion/pivotal-common/trunk/js-common/

vendor - ant    https://svn.pivotallabs.com/subversion/ant

vendor/plugins - pivotal_core_bundle           https://svn.pivotallabs.com/subversion/plugins/pivotal_core/pivotal_core_bundle/trunk/pivotal_core_bundle
migrator                      https://svn.pivotallabs.com/subversion/plugins/pivotal_core/migrator/trunk/migrator
seleniumrc_fu                 https://svn.pivotallabs.com/subversion/plugins/third_party/seleniumrc_fu/branches/local/seleniumrc_fu
subversion_helper             https://svn.pivotallabs.com/subversion/plugins/pivotal_core/subversion_helper/trunk/subversion_helper
EOF

  def test_parse
    assert_equal({
     "vendor/plugins/pivotal_core_bundle" => "https://svn.pivotallabs.com/subversion/plugins/pivotal_core/pivotal_core_bundle/trunk/pivotal_core_bundle",
     "vendor/plugins/migrator" => "https://svn.pivotallabs.com/subversion/plugins/pivotal_core/migrator/trunk/migrator",
     "vendor/plugins/seleniumrc_fu" => "https://svn.pivotallabs.com/subversion/plugins/third_party/seleniumrc_fu/branches/local/seleniumrc_fu",
     "vendor/plugins/subversion_helper" => "https://svn.pivotallabs.com/subversion/plugins/pivotal_core/subversion_helper/trunk/subversion_helper",
     "public/javascripts/js-common" => "https://svn.pivotallabs.com/subversion/pivotal-common/trunk/js-common/",
     "vendor/ant" => "https://svn.pivotallabs.com/subversion/ant"}, SubversionPropgetParser.new.parse(PROPGET_ENTRY))
  end
end

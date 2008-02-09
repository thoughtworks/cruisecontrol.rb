require File.dirname(__FILE__) + '/../../test_helper'
require 'revision'
require 'changeset_entry'

class Subversion::LogParserTest < Test::Unit::TestCase

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
     "vendor/ant" => "https://svn.pivotallabs.com/subversion/ant"}, Subversion::PropgetParser.new.parse(PROPGET_ENTRY))
  end

PROPGET_ENTRY_WITH_FROZEN_EXTERNALS = <<-EOF
public/javascripts/jsunit - jsunit https://svn.pivotallabs.com/subversion/jsunit/branches/local

vendor - desert https://svn.pivotallabs.com/subversion/plugins/third_party/desert/branches/local

vendor/plugins - acts_as_list                  https://svn.pivotallabs.com/subversion/plugins/third_party/acts_as_list/branches/local
acts_as_paranoid              https://svn.pivotallabs.com/subversion/plugins/third_party/acts_as_paranoid/branches/local
acts_as_tree                  https://svn.pivotallabs.com/subversion/plugins/third_party/acts_as_tree/branches/local
addressbookimporter           https://svn.pivotallabs.com/subversion/plugins/socialitis/addressbookimporter/trunk/addressbookimporter
blogs                         https://svn.pivotallabs.com/subversion/plugins/socialitis/blogs/trunk/blogs
bluecloth                     https://svn.pivotallabs.com/subversion/plugins/third_party/bluecloth/branches/local
cacheable_flash               https://svn.pivotallabs.com/subversion/plugins/third_party/cacheable_flash/branches/local
enumerations_mixin            https://svn.pivotallabs.com/subversion/plugins/third_party/enumerations_mixin/branches/local/enumerations_mixin
exception_notification        https://svn.pivotallabs.com/subversion/plugins/third_party/exception_notification/branches/local
fixture_utils                 https://svn.pivotallabs.com/subversion/plugins/pivotal_other/fixture_utils/trunk/fixture_utils
groups                        https://svn.pivotallabs.com/subversion/plugins/socialitis/groups/trunk/groups
invitations                   https://svn.pivotallabs.com/subversion/plugins/socialitis/invitations/trunk/invitations
message_center                https://svn.pivotallabs.com/subversion/plugins/socialitis/message_center/trunk/message_center
migrator                      https://svn.pivotallabs.com/subversion/plugins/pivotal_core/migrator/trunk/migrator
pivotal_core_bundle    -r84531       https://svn.pivotallabs.com/subversion/plugins/pivotal_core/pivotal_core_bundle/trunk/pivotal_core_bundle
rspec                         https://svn.pivotallabs.com/subversion/plugins/third_party/rspec/tags/vendor_rev_2791
rspec_on_rails                https://svn.pivotallabs.com/subversion/plugins/third_party/rspec_on_rails/tags/vendor_rev_2791
ruby-guid-0.0.1               https://svn.pivotallabs.com/subversion/plugins/third_party/ruby-guid/branches/vendor/ruby-guid-0.0.1
secure_actions                https://svn.pivotallabs.com/subversion/plugins/third_party/secure_actions/branches/local/secure_actions
seleniumrc_fu                 https://svn.pivotallabs.com/subversion/plugins/third_party/seleniumrc_fu/branches/local
storage_service               https://svn.pivotallabs.com/subversion/plugins/pivotal_other/storage_service/trunk/storage_service
subversion_helper             https://svn.pivotallabs.com/subversion/plugins/pivotal_core/subversion_helper/trunk/subversion_helper
user                          https://svn.pivotallabs.com/subversion/plugins/socialitis/user/trunk/user
validates_captcha             https://svn.pivotallabs.com/subversion/plugins/third_party/validates_captcha/branches/local
will_paginate                 https://svn.pivotallabs.com/subversion/plugins/third_party/will_paginate/branches/local
bookmark_fu                   https://svn.pivotallabs.com/subversion/plugins/third_party/bookmark_fu/branches/local/bookmark_fu
EOF
  
  def test_parse__when_frozen_external__should_not_include_it_in_the_list
    entries = Subversion::PropgetParser.new.parse(PROPGET_ENTRY_WITH_FROZEN_EXTERNALS)
    assert_nil entries["vendor/plugins/pivotal_core_bundle"]
#    assert_equal "https://svn.pivotallabs.com/subversion/plugins/pivotal_core/pivotal_core_bundle/trunk/pivotal_core_bundle", entries["vendor/plugins/pivotal_core_bundle"]
  end
end

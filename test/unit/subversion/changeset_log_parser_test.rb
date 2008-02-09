require File.dirname(__FILE__) + '/../../test_helper'
require 'revision'
require 'changeset_entry'

class Subversion::ChangesetLogParserTest < Test::Unit::TestCase

LOG_WITH_SINGLE_REVISION = <<EOF
Revision 204.1 committed by leonard0 on 2007-02-12 15:32:55
Detect when X occurs and trigger Y to happen.
  M /trunk/app/models/project.rb
  M /trunk/test/unit/project_test.rb
EOF

LOG_WITH_MULTIPLE_REVISIONS = <<EOF
Revision 189 committed by joepoon on 2007-02-11 02:24:27
Checking in code comment.
  A /trunk/app/models/build_status.rb
  M /trunk/test/unit/status_test.rb

Revision 190 committed by alexeyv on 2007-02-11 15:34:43
Radical refactoring.
  M /trunk/app/controllers/projects_controller.rb
  M /trunk/app/models/projects.rb
  M /trunk/app/views/projects/index.rhtml
EOF

LOG_WITH_NO_COMMENT = <<EOF
Revision 204.1 committed by leonard0 on 2007-02-12 15:32:55

  M /trunk/app/models/project.rb
  M /trunk/test/unit/project_test.rb
EOF

LOG_WITH_MULTIPLE_LINED_COMMENT = <<EOF
Revision 42 committed by ninja on 2007-02-12 02:32:55

Line one

Line two

  M /trunk/app/foo.rb
  M /trunk/tests/foo_test.rb
EOF

  def test_can_parse_LOG_WITH_SINGLE_REVISION
    expected_result = [Revision.new(204.1, 'leonard0', DateTime.parse('2007-02-12 15:32:55'), 
                                    'Detect when X occurs and trigger Y to happen.',
                                    [ChangesetEntry.new('M', '/trunk/app/models/project.rb'),
                                     ChangesetEntry.new('M', '/trunk/test/unit/project_test.rb')])]
    assert_equal expected_result, Subversion::ChangesetLogParser.new.parse_log(LOG_WITH_SINGLE_REVISION.split("\n"))
  end
  
  def test_can_parse_LOG_WITH_MULTIPLE_REVISIONS
    expected_result = [Revision.new(189, 'joepoon', DateTime.parse('2007-02-11 02:24:27'), 
                                    'Checking in code comment.',
                                    [ChangesetEntry.new('A', '/trunk/app/models/build_status.rb'),
                                     ChangesetEntry.new('M', '/trunk/test/unit/status_test.rb')]),
                       Revision.new(190, 'alexeyv', DateTime.parse('2007-02-11 15:34:43'), 
                                    'Radical refactoring.',
                                    [ChangesetEntry.new('M', '/trunk/app/controllers/projects_controller.rb'),
                                     ChangesetEntry.new('M', '/trunk/app/models/projects.rb'),
                                     ChangesetEntry.new('M', '/trunk/app/views/projects/index.rhtml')])]
                                                                          
    assert_equal expected_result, Subversion::ChangesetLogParser.new.parse_log(LOG_WITH_MULTIPLE_REVISIONS.split("\n"))
  end
  
  def test_can_parse_LOG_WITH_NO_COMMENT
    expected_result = [Revision.new(204.1, 'leonard0', DateTime.parse('2007-02-12 15:32:55'), 
                                    '',
                                    [ChangesetEntry.new('M', '/trunk/app/models/project.rb'),
                                     ChangesetEntry.new('M', '/trunk/test/unit/project_test.rb')])]
    assert_equal expected_result, Subversion::ChangesetLogParser.new.parse_log(LOG_WITH_NO_COMMENT.split("\n"))  
  end
  
  def test_can_parse_LOG_WITH_MULTIPLE_LINED_COMMENT
    expected_result = [Revision.new(42, 'ninja', DateTime.parse('2007-02-12 02:32:55'), 
                                    "\nLine one\n\nLine two\n",
                                    [ChangesetEntry.new('M', '/trunk/app/foo.rb'),
                                     ChangesetEntry.new('M', '/trunk/tests/foo_test.rb')])]
    assert_equal expected_result, Subversion::ChangesetLogParser.new.parse_log(LOG_WITH_MULTIPLE_LINED_COMMENT.split("\n"))  
  end  
end
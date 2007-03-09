require File.dirname(__FILE__) + '/../test_helper'
require 'stringio'

class SubversionTest < Test::Unit::TestCase

  LOG_ENTRY = <<-EOF
------------------------------------------------------------------------
r18 | alexeyv | 2007-01-11 13:58:58 -0700 (Thu, 11 Jan 2007) | 1 line

Goofin around with integration test for the builder
------------------------------------------------------------------------
r17 | alexeyv | 2007-01-11 12:44:54 -0700 (Thu, 11 Jan 2007) | 1 line

Moved builder from vendor, made bulder's integration tests
talk to a subversion repository in the local file system
------------------------------------------------------------------------
r15 | stellsmi | 2007-01-11 10:37:32 -0700 (Thu, 11 Jan 2007) | 1 line

integration test does a checkout
------------------------------------------------------------------------
  EOF

  EMPTY_LOG = <<-EOF
------------------------------------------------------------------------
  EOF

  def test_options
    svn = Subversion.new(:url => "file://foo", :username => "bob", :password => 'cha')

    assert_equal("file://foo", svn.url)
    assert_equal("bob", svn.username)
    assert_equal("cha", svn.password)
  end

  def test_only_except_known_options
    assert_raises("don't know how to handle 'sugar'") do
      Subversion.new(:sugar => "1/2 cup")
    end
  end

  def test_update_with_revision_number
    revision_number = 10

    svn = Subversion.new
    svn.expects(:execute).with("svn --non-interactive update --revision #{revision_number}").returns("your mom")

    svn.update(dummy_project, Revision.new(revision_number))
  end

  def test_latest_revision
    svn = Subversion.new

    svn.expects(:info).with(dummy_project).returns('Last Changed Rev' => '10')
    svn.expects(:execute).with("svn --non-interactive log --revision HEAD:10 --verbose").yields(StringIO.new(LOG_ENTRY))

    revision = svn.latest_revision(dummy_project)

    assert_equal 18, revision.number
  end

  def test_revisions_since_should_reverse_the_log_entries_and_skip_the_one_corresponding_to_current_revision
    svn = Subversion.new

    svn.expects(:execute).with("svn --non-interactive log --revision HEAD:15 --verbose").yields(StringIO.new(LOG_ENTRY))

    revisions = svn.revisions_since(dummy_project, 15)

    assert_equal [17, 18], numbers(revisions)
  end

  def test_revisions_since_should_return_all_revisions_when_curreent_revision_is_not_in_the_log_output
    svn = Subversion.new

    svn.expects(:execute).with("svn --non-interactive log --revision HEAD:14 --verbose").yields(StringIO.new(LOG_ENTRY))

    revisions = svn.revisions_since(dummy_project, 14)

    assert_equal [15, 17, 18], numbers(revisions)
  end

  def test_revisions_since_should_return_an_empty_array_for_empty_log_output
    svn = Subversion.new

    svn.expects(:execute).with("svn --non-interactive log --revision HEAD:14 --verbose").yields(StringIO.new(EMPTY_LOG))

    revisions = svn.revisions_since(dummy_project, 14)

    assert_equal [], numbers(revisions)
  end

  def test_checkout_with_no_user_password
    svn = Subversion.new(:url => 'http://foo.com/svn/project')
    svn.expects(:execute).with("svn --non-interactive co http://foo.com/svn/project .")

    svn.checkout('.')
  end

  def test_checkout_with_user_password
    svn = Subversion.new(:url => 'http://foo.com/svn/project', :username => 'jer', :password => "crap")
    svn.expects(:execute).with("svn --non-interactive co http://foo.com/svn/project . --username jer --password crap")

    svn.checkout('.')
  end

  def test_checkout_with_revision
    svn = Subversion.new(:url => 'http://foo.com/svn/project')
    svn.expects(:execute).with("svn --non-interactive co http://foo.com/svn/project . --revision 5")

    svn.checkout('.', Revision.new(5))
  end
  
  def test_allowing_interaction
    svn = Subversion.new(:url => 'svn://foo.com/', :interactive => true)
    svn.expects(:execute).with("svn co svn://foo.com/ .")
    svn.checkout('.')
    svn.verify
  end

  def test_checkout_requires_url
    assert_raises('URL not specified') { Subversion.new.checkout('.') }
  end

  def test_new_does_not_allow_random_params
    assert_raises("don't know how to handle 'lollipop'") do
      Subversion.new(:url => 'http://foo.com/svn/project', :lollipop => 'http://foo.com/svn/project')
    end
  end

  def numbers(revisions)
    revisions.map { |r|
      r.number
    }
  end

  DummyProject = Struct.new :local_checkout
  def dummy_project
    DummyProject.new('.')
  end

end

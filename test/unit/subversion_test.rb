require File.dirname(__FILE__) + '/../test_helper'
require 'stringio'

class SubversionTest < Test::Unit::TestCase
  include FileSandbox
  
  def teardown
    FileUtils.rm_f "./svn.err"
  end

  LOG_ENTRY = <<-EOF
<log>
<logentry revision="18">
  <author>alexey</author>
  <date>2006-01-11T13:58:58.000007Z</date>
  <msg>Goofin around with integration test for the builder</msg>
</logentry>
<logentry revision="17">
  <author>alexey</author>
  <date>2006-01-11T12:44:54.000007Z</date>
  <msg>Moved builder from vendor, made bulder's integration tests talk to a subversion repository in the local file system</msg>
</logentry>
<logentry revision="15">
  <author>stellsmi</author>
  <date>2006-01-11T10:37:32.000007Z</date>
  <msg>integration test does a checkout</msg>
</logentry>
</log>
  EOF

  EMPTY_LOG = <<-EOF
<log></log>
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
    svn.expects(:execute).with("svn --non-interactive update --revision #{revision_number}", {:stderr => './svn.err'}).returns("your mom")

    svn.update(dummy_project, Revision.new(revision_number))
  end

  def test_latest_revision
    svn = Subversion.new

    svn.expects(:info).with(dummy_project).returns(Subversion::Info.new(10, 10))
    svn.expects(:execute).with("svn --non-interactive log --revision HEAD:10 --verbose --xml", {:stderr => './svn.err'}).yields(StringIO.new(LOG_ENTRY))

    revision = svn.latest_revision(dummy_project)

    assert_equal 18, revision.number
  end

  def test_revisions_since_should_reverse_the_log_entries_and_skip_the_one_corresponding_to_current_revision
    svn = Subversion.new

    svn.expects(:execute).with("svn --non-interactive log --revision HEAD:15 --verbose --xml", {:stderr => './svn.err'}).yields(StringIO.new(LOG_ENTRY))

    revisions = svn.revisions_since(dummy_project, 15)

    assert_equal [17, 18], numbers(revisions)
  end

  def test_revisions_since_should_return_all_revisions_when_curreent_revision_is_not_in_the_log_output
    svn = Subversion.new

    svn.expects(:execute).with("svn --non-interactive log --revision HEAD:14 --verbose --xml", {:stderr => './svn.err'}).yields(StringIO.new(LOG_ENTRY))

    revisions = svn.revisions_since(dummy_project, 14)

    assert_equal [15, 17, 18], numbers(revisions)
  end

  def test_revisions_since_should_return_an_empty_array_for_empty_log_output
    svn = Subversion.new

    svn.expects(:execute).with("svn --non-interactive log --revision HEAD:14 --verbose --xml", {:stderr => './svn.err'}).yields(StringIO.new(EMPTY_LOG))

    revisions = svn.revisions_since(dummy_project, 14)

    assert_equal [], numbers(revisions)
  end

  def test_checkout_with_no_user_password
    svn = Subversion.new(:url => 'http://foo.com/svn/project')
    svn.expects(:execute).with("svn --non-interactive co http://foo.com/svn/project .")

    svn.checkout('.')
  end

  def test_should_write_error_info_to_log_when_svn_server_not_available
    in_sandbox do |sandbox|
      sandbox.new :file => "project/work/empty", :with_content => ""
      project = Object.new
      project.stubs(:local_checkout).returns("#{sandbox.root}/project/work")
      project.stubs(:path).returns("#{sandbox.root}/project")
      svn = Subversion.new
      begin
        svn.revisions_since(project, 1)
        flunk
      rescue BuilderError => e
        assert_match /not a working copy/, e.message
      end
      
    end
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
  
  def test_clean_checkout
    in_sandbox do
      @sandbox.new :file => 'project/something.rb'
      dir = @sandbox.root + "/project"

      svn = Subversion.new(:url => 'http://foo.com/svn/project')
      svn.expects(:execute).with("svn --non-interactive co http://foo.com/svn/project #{dir} --revision 5")

      svn.clean_checkout(dir, Revision.new(5))
      
      assert !File.directory?(dir)
    end    
  end

  def numbers(revisions)
    revisions.map { |r|
      r.number
    }
  end

  DummyProject = Struct.new :local_checkout, :path
  def dummy_project
    DummyProject.new('.', '.')
  end

end

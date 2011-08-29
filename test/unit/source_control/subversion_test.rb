require 'test_helper'

class SourceControl::SubversionTest < ActiveSupport::TestCase

  include FileSandbox
  include SourceControl

  def teardown
    FileUtils.rm_f "./source_control.err"
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
    svn = Subversion.new(:repository => "file://foo",
                         :username => "bob",
                         :password => 'cha',
                         :path => "bob",
                         :error_log => "bob/source_control.err")

    assert_equal("file://foo", svn.repository)
    assert_equal("bob", svn.username)
    assert_equal("cha", svn.password)
    assert_equal("bob", svn.path)
    assert_equal("bob/source_control.err", svn.error_log)
  end

  def test_error_log_should_default_to_above_path
    assert_equal("bob/../source_control.err", Subversion.new(:path => "bob").error_log)
    assert_equal("./../source_control.err", Subversion.new.error_log)

    assert_equal(".", Subversion.new.path)
  end

  def test_only_except_known_options
    assert_raise_with_message(RuntimeError, "don't know how to handle 'sugar'") do
      Subversion.new(:sugar => "1/2 cup")
    end
  end

  def test_update_with_revision_number
    revision_number = 10

    svn = new_subversion
    svn.expects(:svn).with("update", ["--revision", revision_number]).returns(["your mom"])

    svn.update(Subversion::Revision.new(revision_number))
  end

  def test_latest_revision
    svn = new_subversion
    svn.expects(:log).with("HEAD", "1", ["--limit", "1"]).returns(LOG_ENTRY.split("\n"))

    revision = svn.latest_revision

    assert_equal 18, revision.number
  end

  def test_externals
    svn = new_subversion
    svn.expects(:svn).with("propget", ["-R", "svn:externals"]).returns("propget results")
    parser = mock("parser")
    Subversion::PropgetParser.expects(:new).returns(parser)
    parser.expects(:parse).returns("parse results")

    assert_equal("parse results", svn.externals)
  end

  def test_checkout_with_no_user_password
    svn = new_subversion(:repository => 'http://foo.com/svn/project')
    svn.expects(:svn).with("co", ["http://foo.com/svn/project", "."],
                           :execute_in_project_directory => false)

    svn.checkout
  end

  def test_checkout_to_a_different_path
    svn = new_subversion(:repository => 'http://foo.com/svn/project')
    svn.expects(:svn).with("co", ["http://foo.com/svn/project", "somewhere"],
                           :execute_in_project_directory => false)

    svn.checkout(nil, $stdout, "somewhere")
  end

# TODO: rewrite once "SourceControl::AbstractAdapter#execute_with_error_log" is fixed  
#  def test_should_write_error_info_to_log_when_svn_server_not_available
#    in_sandbox do |sandbox|
#      sandbox.new :file => "project/work/empty", :with_content => ""
#      svn = new_subversion(:path => "project/work", :error_log => "project/source_control.err")
#      begin
#        svn.up_to_date?
#        flunk
#      rescue BuilderError => e
#        assert_match /not a working copy/, e.message
#      end
#    end
#  end

  def test_checkout_with_user_password
    svn = new_subversion(:repository => 'http://foo.com/svn/project', :username => 'jer', :password => "crap")
    svn.expects(:svn).with("co", ["http://foo.com/svn/project", ".", "--username",
                                "jer", "--password", "crap"], :execute_in_project_directory => false)

    svn.checkout
  end

  def test_configure_subversion_not_to_check_externals
    svn = Subversion.new(:check_externals => false)
    assert_equal false, svn.check_externals

    svn = Subversion.new(:check_externals => true)
    assert_equal true, svn.check_externals

    svn.check_externals = false
    assert_equal false, svn.check_externals
  end

  def test_checkout_with_revision
    svn = Subversion.new(:repository => 'http://foo.com/svn/project')
    svn.expects(:svn).with("co", ["http://foo.com/svn/project", ".", "--revision", 5],
                           :execute_in_project_directory => false)

    svn.checkout(Subversion::Revision.new(5))
  end

  def test_allowing_interaction
    svn = new_subversion(:repository => 'svn://foo.com/', :interactive => true)
    svn.expects(:svn).with("co", ["svn://foo.com/", "."], :execute_in_project_directory => false)
    svn.checkout
  end

  def test_checkout_requires_repository_location
    assert_raise_with_message(BuilderError, "'.' is not a working copy") { Subversion.new.checkout('.') }
  end

  def test_new_does_not_allow_random_params
    assert_raise_with_message(RuntimeError, "don't know how to handle 'lollipop'") do
      Subversion.new(:repository => 'http://foo.com/svn/project', :lollipop => 'http://foo.com/svn/project')
    end
  end

  def test_clean_checkout
    in_sandbox do
      @sandbox.new :file => 'project/something.rb'
      assert File.directory?("project")

      svn = Subversion.new(:repository => 'http://foo.com/svn/project', :path => "project")
      svn.expects(:svn).with("co", ["http://foo.com/svn/project", "project.new", "--revision", 5],
                             :execute_in_project_directory => false)

      svn.clean_checkout(Subversion::Revision.new(5))

      assert !File.directory?("project")
    end
  end

  def test_output_of_subversion_to_io_stream
    in_sandbox do
      svn = Subversion.new(:repository => 'url')
      def svn.svn(*args, &block)
        execute_in_local_copy 'echo hello world', {}, &block
      end

      io = StringIO.new
      svn.checkout(Subversion::Revision.new(5), io)

      assert_equal "hello world\n", io.string
    end
  end

  def test_up_to_date_should_deal_with_different_revisions
    in_sandbox do
      svn = new_subversion
      svn.expects(:last_locally_known_revision).returns(Subversion::Revision.new(1))
      svn.expects(:latest_revision).returns(Subversion::Revision.new(4))
      svn.expects(:revisions_since).with(1).returns([Subversion::Revision.new(2), Subversion::Revision.new(4)])
      svn.expects(:externals).returns([])
      assert !svn.up_to_date?(reasons = [])
      assert_equal [ "New revision 4 detected", Subversion::Revision.new(2), Subversion::Revision.new(4) ], reasons
    end
  end

  def test_last_locally_known_revision_should_return_zero_if_path_doesnt_exist
    svn = new_subversion :path => "foo"

    assert_equal 0, svn.last_locally_known_revision.number
  end

  def test_up_to_date_should_deal_with_same_revisions
    in_sandbox do
      svn = new_subversion
      svn.expects(:last_locally_known_revision).returns(Subversion::Revision.new(1))
      svn.expects(:latest_revision).returns(Subversion::Revision.new(1))
      svn.expects(:externals).returns([])

      assert svn.up_to_date?(reasons = [])
      assert_equal [], reasons
    end
  end

  def test_up_to_date_should_check_externals_and_return_false
    in_sandbox do
      sandbox.new :directory => "a"
      sandbox.new :directory => "b"

      svn = new_subversion
      a_svn = Object.new
      b_svn = new_subversion
      Subversion.expects(:new).with(:path => "./a", :repository => "svn+ssh://a", :check_externals => false).returns(a_svn)
      Subversion.expects(:new).with(:path => "./b", :repository => "svn+ssh://b", :check_externals => false).returns(b_svn)

      svn.check_externals = true
      svn.expects(:externals).returns({"a" => "svn+ssh://a", "b" => "svn+ssh://b"})
      svn.expects(:latest_revision).returns(Subversion::Revision.new(14))
      a_svn.expects(:up_to_date?).returns(true)
      b_svn.expects(:last_locally_known_revision).returns(Subversion::Revision.new(20))
      b_svn.expects(:latest_revision).returns(Subversion::Revision.new(30))
      b_svn.expects(:revisions_since).with(20).returns([Subversion::Revision.new(24)])
      b_svn.expects(:externals).returns({})

      assert !svn.up_to_date?(reasons = [], 14)
      assert_equal ["New revision 30 detected in external 'b'", Subversion::Revision.new(24)], reasons
    end
  end

  def test_up_to_date_should_check_externals_and_return_true
    in_sandbox do
      sandbox.new :directory => "a"
      sandbox.new :directory => "b"

      svn = new_subversion
      a_svn = Object.new
      b_svn = Object.new
      Subversion.expects(:new).with(:path => "./a", :repository => "svn+ssh://a", :check_externals => false).returns(a_svn)
      Subversion.expects(:new).with(:path => "./b", :repository => "svn+ssh://b", :check_externals => false).returns(b_svn)

      svn.check_externals = true
      svn.expects(:externals).returns({"a" => "svn+ssh://a", "b" => "svn+ssh://b"})
      svn.expects(:latest_revision).returns(Subversion::Revision.new(14))
      a_svn.expects(:up_to_date?).returns(true)
      b_svn.expects(:up_to_date?).returns(true)

      assert svn.up_to_date?(reasons = [], 14)
      assert_equal [], reasons
    end
  end

  def test_repository_detected_by_svn_info_if_not_provided
    info = Struct.new(:url).new
    info.url = 'svn://example.org/repo'

    svn = new_subversion
    svn.expects(:info).returns(info)
    assert_equal svn.repository, info.url
  end

  def numbers(revisions)
    revisions.map { |r|
      r.number
    }
  end

  def new_subversion(options = {})
    Subversion.new({:path => '.', :error_log => "./source_control.err"}.merge(options))
  end

end

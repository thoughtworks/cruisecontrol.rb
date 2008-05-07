require File.dirname(__FILE__) + '/../../test_helper'

class MercurialTest < Test::Unit::TestCase

  def setup
    @parser = mock("parser")
    @mercurial = Mercurial.new(@parser)
  end

  def test_update
    @mercurial.expects(:hg).with("").returns("pull")
    @mercurial.expects(:execute).with("pull")
    @mercurial.expects(:update_command).with(revision).returns("update")
    @mercurial.expects(:execute).with("update")
    @mercurial.update(project, revision)
  end

  def test_latest_revision
    @parser.expects(:parse_log).with("log_result").returns(["foo"])
    project = mock("project")
    project.expects(:local_checkout).returns("/tmp")
    @mercurial.expects(:pull_command).returns("pull")
    @mercurial.expects(:execute).with("pull")

    @mercurial.expects(:log_command).with("tip").returns("log")
    @mercurial.expects(:execute).with("log").returns("log_result")
    assert_equal("foo", @mercurial.latest_revision(project))
  end

end

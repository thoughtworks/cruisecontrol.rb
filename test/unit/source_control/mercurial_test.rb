require File.dirname(__FILE__) + '/../../test_helper'

module SourceControl
  class MercurialTest < Test::Unit::TestCase

    include FileSandbox

    def setup
      @mercurial = Mercurial.new
    end

    def test_update
      in_sandbox do
        revision = Mercurial::Revision.new('abcde') 
        @mercurial.expects(:hg).with("pull")
        @mercurial.expects(:hg).with("update", ['-r', 'abcde'])
        @mercurial.update(revision)
      end
    end

    def test_latest_revision
      in_sandbox do
        parser = mock('parser')
        parser.expects(:parse).with("log_result").returns(["foo"])
        Mercurial::LogParser.expects(:new).returns(parser)

        @mercurial.expects(:hg).with("pull")
        @mercurial.expects(:hg).with("log", ['-v', '-r', 'tip']).returns("log_result")
        assert_equal("foo", @mercurial.latest_revision)
      end
    end

    def test_update
      in_sandbox do
        stub_revision = stub('revision', :number => '12345')
        @mercurial.expects(:hg).with('pull')
        @mercurial.expects(:hg).with('update', ['-r', '12345'])
        assert_nothing_raised { @mercurial.update(stub_revision) }
      end
    end

    def test_update_with_no_revision_specified
      in_sandbox do
        @mercurial.expects(:hg).with('pull')
        @mercurial.expects(:hg).with('update')
        assert_nothing_raised { @mercurial.update }
      end
    end

    # TODO tests for other public methods of this class

  end
end

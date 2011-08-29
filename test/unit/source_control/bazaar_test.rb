require 'test_helper'

module SourceControl
  class BazaarTest < Test::Unit::TestCase

    include FileSandbox

    def setup
      @bazaar = Bazaar.new
    end

    def test_update
      in_sandbox do
        revision = Bazaar::Revision.new('5')
        @bazaar.expects(:bzr).with("revert", ['-r', '5'])
        @bazaar.update(revision)
      end
    end

    def test_latest_revision
      in_sandbox do
        parser = mock('parser')
        parser.expects(:parse).with("log_result").returns(["foo"])
        Bazaar::LogParser.expects(:new).returns(parser)

        @bazaar.expects(:bzr).with("pull")
        @bazaar.expects(:bzr).with("log", ['-v', '-r', '-1']).returns("log_result")
        assert_equal("foo", @bazaar.latest_revision)
      end
    end

    def test_update
      in_sandbox do
        stub_revision = stub('revision', :number => '12345')
        @bazaar.expects(:bzr).with('revert', ['-r', '12345'])
        assert_nothing_raised { @bazaar.update(stub_revision) }
      end
    end

    def test_update_with_no_revision_specified
      in_sandbox do
        @bazaar.expects(:bzr).with('pull')
        assert_nothing_raised { @bazaar.update }
      end
    end

    def test_checkout
      bazaar_with_checkout_data = Bazaar.new(:repository => '/tmp/bzr_repo')
      in_sandbox do
        bazaar_with_checkout_data.expects(:bzr).with(
            'branch', ['/tmp/bzr_repo', '.'], :execute_in_project_directory => false)
        assert_nothing_raised { bazaar_with_checkout_data.checkout }
      end
    end

    def test_checkout_to_a_given_directory
      bzr = Bazaar.new(:repository => '/tmp/bzr_repo')
      in_sandbox do |sandbox|
        bzr.expects(:bzr).with('branch', ['/tmp/bzr_repo', 'somewhere'], :execute_in_project_directory => false)
        FileUtils.mkdir File.join(sandbox.root, "somewhere")
        assert_nothing_raised { bzr.checkout(nil, $stdout, 'somewhere') }
      end
    end

    # TODO tests for other public methods of this class

  end
end

require 'test_helper'

class SourceControl::AbstractAdapterTest < ActiveSupport::TestCase
  include FileSandbox

  def test_execute_with_error_log__handles_exceptions
    @adapter = SourceControl::AbstractAdapter.new
    in_total_sandbox do
      assert_raise(BuilderError) do
              @adapter.execute_with_error_log("xaswedf", @stderr)
            end
    end
  end

  def test_execute_with_error_log__shows_all_lines_of_multiline_exceptions
    @adapter = SourceControl::AbstractAdapter.new
    in_total_sandbox do
      assert_raise(BuilderError, /svn:.*svn:/m) do
              @adapter.execute_with_error_log("svn co file://foo/bar", @stderr)
            end
    end
  end

  def test_execute_with_error_log__handles_ExecutionError
    @adapter = SourceControl::AbstractAdapter.new
    in_total_sandbox do
      assert_raise(BuilderError) do
              @adapter.execute_with_error_log("xaswedf", @stderr)
            end
    end
  end
end
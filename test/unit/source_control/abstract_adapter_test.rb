require File.dirname(__FILE__) + '/../../test_helper'
require 'stringio'

class SourceControl::AbstractAdapterTest < Test::Unit::TestCase

  include FileSandbox

  def test_execute_with_error_log__handles_exceptions
    @adapter = SourceControl::AbstractAdapter.new
    in_total_sandbox do
      assert_raise(BuilderError) do
              @adapter.execute_with_error_log("xaswedf", @stderr)
            end
    end
  end
end
require File.dirname(__FILE__) + '/../test_helper'

class ServerTest < Test::Unit::TestCase

  def test_load_server_does_nothing_if_file_doesnt_exist
    Server.new('madeup_dir').load
  end
end
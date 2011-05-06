require 'test_helper'

class BuilderPluginTest < ActiveSupport::TestCase
  
  def test_builder_plugin_should_maintain_list_of_known_events
    assert BuilderPlugin.known_event? :build_requested
    assert_false BuilderPlugin.known_event? :some_random_event
  end
  
end
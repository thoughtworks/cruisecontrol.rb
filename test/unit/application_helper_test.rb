require 'test_helper'

class ApplicationHelperTest < Test::Unit::TestCase
  
  def setup
    @helper = Object.new.extend(ApplicationHelper)
  end

  def test_format_time_sends_to_time_formatter
    time_formatter = mock()
    time_formatter.expects(:human)
    time = Time.parse('2009-07-01 12:30:00')
    TimeFormatter.expects(:new).with(time).returns(time_formatter)
    @helper.format_time(time, :human)
  end

  def test_format_time_defaults_to_iso
    time_formatter = mock()
    time_formatter.expects(:iso)
    time = Time.parse('2009-07-01 12:30:00')
    TimeFormatter.expects(:new).with(time).returns(time_formatter)
    @helper.format_time(time)
  end

  def test_format_seconds_sends_to_duration_formatter
    duration_formatter = mock()
    duration_formatter.expects(:precise)
    DurationFormatter.expects(:new).with(0).returns(duration_formatter)
    @helper.format_seconds(0, :precise)
  end

  def test_format_seconds_defaults_to_general
    duration_formatter = mock()
    duration_formatter.expects(:general)
    DurationFormatter.expects(:new).with(0).returns(duration_formatter)
    @helper.format_seconds(0)
  end

  def test_format_changeset_log_strips_html_tags
    @helper.extend(ERB::Util)
    assert_equal "&lt;hr /&gt;some changeset&lt;script&gt;alert('bad')&lt;/script&gt;",
     @helper.format_changeset_log("<hr />some changeset<script>alert('bad')</script>")
  end
  
  def test_build_link_includes_title
    @helper.extend(ERB::Util)
    project = stub(:name => "name")
    build = stub(:label => "label", :status => "status", :changeset => "changeset")
    @helper.stubs(:build_path).with(:project => "name", :build => "label").returns("build_path")
    @helper.expects(:link_to).with("text", "build_path", {:class => "status", :title => "changeset"})
    @helper.build_link("text", project, build)
  end
  
end

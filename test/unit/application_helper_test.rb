require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  
  def setup
    @helper = Object.new.extend(ApplicationHelper)
  end

  context "ApplicationHelper#format_time" do
    test "should pass whatever format argument it's given to I18n.l" do
      I18n.expects(:l).with(:time, :format => :human)
      @helper.format_time(:time, :human)
    end

    test "should default to the ISO formatter if no format is given" do
      I18n.expects(:l).with(:time, :format => :iso)
      @helper.format_time(:time)
    end
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

  context "ApplicationHelper#human_time" do
    test "should include the year when the time occurred before this year" do
      Time.stubs(:now).returns(Time.parse('2009-07-01 00:00:00'))
      assert_equal '31 Dec 08', @helper.human_time(Time.parse('2008-12-31 23:59:59'))
    end

    test "should include the month when the time occurred before today" do
      Time.stubs(:now).returns(Time.parse('2009-07-01 00:00:00'))
      assert_equal '1 Jun',  @helper.human_time(Time.parse('2009-06-01 00:00:00'))
      assert_equal '30 Jun', @helper.human_time(Time.parse('2009-06-30 23:59:59'))
    end

    test "should only render the time when time occurs today" do
      Time.stubs(:now).returns(Time.parse('2009-07-01 00:00:00'))
      assert_equal '0:00',  @helper.human_time(Time.parse('2009-07-01 00:00:00'))
      assert_equal '0:01',  @helper.human_time(Time.parse('2009-07-01 00:01:00'))
      assert_equal '1:02',  @helper.human_time(Time.parse('2009-07-01 01:02:00'))
      assert_equal '1:02',  @helper.human_time(Time.parse('2009-07-01 01:02:59'))
      assert_equal '9:59',  @helper.human_time(Time.parse('2009-07-01 09:59:59'))
      assert_equal '10:00', @helper.human_time(Time.parse('2009-07-01 10:00:00'))
      assert_equal '23:59', @helper.human_time(Time.parse('2009-07-01 23:59:59'))
    end

    test "should indicate that the time is in the future when it occurs after today" do
      Time.stubs(:now).returns(Time.parse('2009-07-01 00:00:00'))
      assert_equal '2009-07-02 00:00:00 ?future?', @helper.human_time(Time.parse('2009-07-02 00:00:00'))
    end
  end
  
end

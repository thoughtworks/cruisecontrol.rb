require File.dirname(__FILE__) + '/../test_helper'

class BreadcrumbTest < Test::Unit::TestCase
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  
  def test_add_crumb
    add_breadcrumb 'Dashboard', '/'
    
    assert_equal link_to('Dashboard', '/'), @breadcrumbs.to_s
  end
  
  def test_add_more
    add_breadcrumb 'Dashboard', '/'
    add_breadcrumb 'proj', '/hoo'
    
    assert_equal link_to('Dashboard', '/') + " > " + link_to('proj', '/hoo'), @breadcrumbs.to_s
  end
end

# $Id: redcloth_template_test.rb 22 2007-01-19 20:01:39Z toupeira $

require 'test/unit'
require 'rubygems'
require 'active_support'
require 'action_controller'
require 'action_view'

require 'init.rb'

class RedClothTemplate < Test::Unit::TestCase
  def render(input, local_assigns={})
    template = RedCloth::Template.new(ActionView::Base.new)
    template.render(input, local_assigns)
  end

  def test_erb
    assert_equal "<p>2</p>", render("<%= 1 + 1 %>")
  end

  def test_textile
    assert_equal "<h1>title</h1>", render("h1. <%= 'title' %>")
  end

  def test_markdown
    assert_equal "<h1>title</h1>", render("<%= 'title' %>\n=====")
  end
end

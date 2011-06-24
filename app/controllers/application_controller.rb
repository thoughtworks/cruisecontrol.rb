# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  def render_not_found
    render :file => Rails.root.join('public', '404.html').to_s, :status => 404
  end

  def disable_build_triggers
    return unless Configuration.disable_admin_ui
    render :text => 'Build requests are not allowed', :status => :forbidden
  end
end

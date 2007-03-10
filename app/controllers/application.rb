# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  session :off

  def render_not_found
    render :file => File.join(RAILS_ROOT, 'public/404.html'), :status => 404
  end
    
end

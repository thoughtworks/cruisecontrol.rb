# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def color_for_status(build)
    build.successful? ? 'green' : 'red'
  end
end

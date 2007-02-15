class DocumentationController < ApplicationController
  def get
    path = File.join('documentation', params[:path]).gsub(/.html$/, '')
    
    if template_exists?(path)
      render :template => path
    elsif template_exists?(path + "/index")
      redirect_to :path => (params[:path] + ['index.html'])
    else
      render_not_found
    end
  end
end

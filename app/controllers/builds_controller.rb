class BuildsController < ApplicationController
  caches_page :drop_down
  
  def show
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    @project = Project.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project

    if params[:build]
      @build = @project.find_build(params[:build])
      render :text => "Build #{params[:build].inspect} not found", :status => 404 and return if @build.nil? 
    else
      @build = @project.last_build
      render :action => 'no_builds_yet' and return if @build.nil?
    end

    @builds_for_navigation_list, @builds_for_dropdown = partitioned_build_lists(@project)

    @autorefresh = @build.incomplete?
  end

  def artifact
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    render :text => 'Build not specified', :status => 404 and return unless params[:build]
    render :text => 'Path not specified', :status => 404 and return unless params[:path]

    @project = Project.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project
    @build = @project.find_build(params[:build])
    render :text => "Build #{params[:build].inspect} not found", :status => 404 and return unless @build

    path = @build.artifact(params[:path])
    
    if File.directory? path
      if File.exists?(File.join(path, 'index.html'))
        redirect_to request.fullpath + '/index.html'
      else
        render :template => 'builds/show_dir_index'
      end
    elsif File.exists? path
      disposition = params.has_key?("attachment") ? "attachment" : "inline"
      send_file(path, :type => get_mime_type(path), :disposition => disposition, :stream => false)
    else
      render_not_found
    end
  end

  def latest_successful
    render :text => 'Project not specified', :status => 404 and return unless params[:project]

    @project = Project.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project
    @build = @project.builds.find_all(&:successful?).last
    render :text => "No successful build found", :status => 404 and return unless @build

    redirect_to build_path(@project, @build) +
                (params[:path] ? "/#{params[:path]}" : "")
  end

  private

    MIME_TYPES = {
      "html" => "text/html",
      "js"   => "text/javascript",
      "css"  => "text/css",
      "gif"  => "image/gif",
      "jpg"  => "image/jpeg",
      "jpeg" => "image/jpeg",
      "png"  => "image/png",
      "zip"  => "application/zip"
    }

    def get_mime_type(name)
      Rack::Mime::MIME_TYPES[File.extname(name)] || "text/plain"
    end

    def partitioned_build_lists(project)
      builds = project.builds.reverse
      partition_point = Configuration.build_history_limit

      return builds[0...partition_point], builds[partition_point..-1] || []
    end

end

module ProjectsHelper

  def rss_title(project, build)
    project.name + (build ? " build #{build.label} #{build.status}" :
                            " has never been built")
  end

  def rss_description(project, build)
    build ? build.changeset : ''
  end

  def rss_pub_date(build)
    format_time(build ? build.time : Time.at(0), :rss)
  end

  def rss_link(project, build)
    build ? build_url(:only_path => false, :project => project, :build => build) :
            project_without_builds_url(:only_path => false, :project => project)            
  end

end
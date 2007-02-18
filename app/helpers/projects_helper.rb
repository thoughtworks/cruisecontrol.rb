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

  def show_revisions_in_build(revisions)
    return '' if revisions.empty?    
    if revisions.length == 1
      revision = revisions[0]
      text = "<div><span class='build_committed_by'>#{revision.committed_by}</span>" + ' committed the checkin</div>'
      # TODO: <br/> - should probably use css instead.
      text += '<br/>'
      text +="<div>Comments:<br/>#{format_changeset_log(revision.message)}</div>" unless revision.message.empty?
      text
    else
      commiters = revisions.collect { |rev| rev.committed_by }.uniq!.join(", ")
      text = "<div><span class='build_committed_by'>#{commiters}</span>" + ' committed the checkin</div>'    
    end
  end

  def revisions_in_build(build)    
    changeset = build.changeset
    ChangesetLogParser.new.parse_log changeset.split("\n")
  end
  
end

require 'digest/md5'

module ProjectsHelper

  def last_commit_avatar project
    email = project.source_control.latest_commiter_email
    hash = Digest::MD5.hexdigest(email)
    image_tag "http://www.gravatar.com/avatar/#{hash}", { :alt => email }
  end

  def rss_title(project, build)
    project.name + (build ? " build #{build.abbreviated_label} #{build.status}" :
                            " has never been built")
  end

  def rss_description(project, build)
    build ? build.changeset : ''
  end

  def rss_pub_date(build)
    time = (build.try(:time) || Time.at(0)).utc
    I18n.l time, :format => :rss
  end

  def rss_link(project, build)
    build ? build_url(:only_path => false, :project => project, :build => build) :
            project_without_builds_url(:only_path => false, :project => project)
  end

  def show_revisions_in_build(revisions)
    return '' if revisions.empty?
    if revisions.length == 1
      revision = revisions[0]
      text = "<div><span class='build_author'>#{revision.author}</span>" + ' committed the checkin</div>'
      # TODO: <br/> - should probably use css instead.
      text += '<br/>'
      text +="<div>Comments:<br/>#{format_changeset_log(revision.message)}</div>" unless revision.message.empty?
      text
    else
      committers = revisions.collect { |rev| rev.author }.uniq
      text = "<div><span class='build_author'>#{committers.join(', ')}</span>" + ' committed the checkin</div>'
    end
  end

  def revisions_in_build(build)
    changeset = build.changeset
    SourceControl::Subversion::ChangesetLogParser.new.parse_log changeset.split("\n")
  end

  # Re-map our project statuses to match the project statuses recognized
  # by CCTray.Net
  def map_to_cctray_project_status(project_status)
    case project_status.to_s
    when 'success', 'building' then 'Success'
    when 'never_built' then 'Unknown'
    when 'failed' then 'Failure'
    else 'Unknown'
    end
  end

  # Re-map our build activities to match the build activities recognized
  # by CCTray.Net
  def map_to_cctray_activity(builder_state)
    case builder_state.to_s
    when 'checking_for_modifications' then 'CheckingModifications'
    when 'building' then 'Building'
    when 'sleeping', 'builder_down' then 'Sleeping'
    else 'Unknown'
    end
  end
  
  def coverage_delta(project)
    '%+0.1f' % project.last_coverage_delta
  end
  
  def coverage_status(coverage)
    Coverage.status(coverage).to_s
  end
end

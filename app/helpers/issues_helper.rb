module IssuesHelper
  def issue_css_classes(issue)
    classes = "issue"
    classes << " closed" if issue.closed?
    classes << " today" if issue.today?
    classes
  end

  # Returns an OpenStruct object suitable for use by <tt>options_from_collection_for_select</tt>
  # to allow filtering issues by an unassigned User or Milestone
  def unassigned_filter
    # Milestone uses :title, Issue uses :name
    OpenStruct.new(id: 0, title: 'None (backlog)', name: 'Unassigned')
  end

  def url_for_project_issues(project = @project)
    return '' if project.nil?

    if project.used_default_issues_tracker? || !external_issues_tracker_enabled?
      project_issues_path(project)
    else
      url = Gitlab.config.issues_tracker[project.issues_tracker]['project_url']
      url.gsub(':project_id', project.id.to_s).
          gsub(':issues_tracker_id', project.issues_tracker_id.to_s)
    end
  end

  def url_for_new_issue(project = @project)
    return '' if project.nil?

    if project.used_default_issues_tracker? || !external_issues_tracker_enabled?
      url = new_project_issue_path project_id: project
    else
      issues_tracker = Gitlab.config.issues_tracker[project.issues_tracker]
      url = issues_tracker['new_issue_url']
      url.gsub(':project_id', project.id.to_s).
          gsub(':issues_tracker_id', project.issues_tracker_id.to_s)
    end
  end

  def url_for_issue(issue_iid, project = @project)
    return '' if project.nil?

    if project.used_default_issues_tracker? || !external_issues_tracker_enabled?
      url = project_issue_url project_id: project, id: issue_iid
    else
      url = Gitlab.config.issues_tracker[project.issues_tracker]['issues_url']
      url.gsub(':id', issue_iid.to_s).
          gsub(':project_id', project.id.to_s).
          gsub(':issues_tracker_id', project.issues_tracker_id.to_s)
    end
  end

  def title_for_issue(issue_iid, project = @project)
    return '' if project.nil?

    if project.used_default_issues_tracker?
      issue = project.issues.where(iid: issue_iid).first
      return issue.title if issue
    end

    ''
  end

  def issue_timestamp(issue)
    # Shows the created at time and the updated at time if different
    ts = "#{time_ago_with_tooltip(issue.created_at, 'bottom', 'note_created_ago')}"
    if issue.updated_at != issue.created_at
      ts << capture_haml do
        haml_tag :small do
          haml_concat " (Edited #{time_ago_with_tooltip(issue.updated_at, 'bottom', 'issue_edited_ago')})"
        end
      end
    end
    ts.html_safe
  end

  # Checks if issues_tracker setting exists in gitlab.yml
  def external_issues_tracker_enabled?
    Gitlab.config.issues_tracker && Gitlab.config.issues_tracker.values.any?
  end

  def bulk_update_milestone_options
    options_for_select(['None (backlog)']) +
        options_from_collection_for_select(project_active_milestones, 'id',
                                           'title', params[:milestone_id])
  end

  def bulk_update_assignee_options(project = @project)
    options_for_select(['None (unassigned)']) +
        options_from_collection_for_select(project.team.members, 'id',
                                           'name', params[:assignee_id])
  end

  def assignee_options(object, project = @project)
    options_from_collection_for_select(project.team.members.sort_by(&:name),
                                       'id', 'name', object.assignee_id)
  end

  def milestone_options(object)
    options_from_collection_for_select(object.project.milestones.active,
                                       'id', 'title', object.milestone_id)
  end

  def issue_box_class(item)
    if item.respond_to?(:expired?) && item.expired?
      'issue-box-expired'
    elsif item.respond_to?(:merged?) && item.merged?
      'issue-box-merged'
    elsif item.closed?
      'issue-box-closed'
    else
      'issue-box-open'
    end
  end

  def issue_to_atom(xml, issue)
    xml.entry do
      xml.id      project_issue_url(issue.project, issue)
      xml.link    href: project_issue_url(issue.project, issue)
      xml.title   truncate(issue.title, length: 80)
      xml.updated issue.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
      xml.media   :thumbnail, width: "40", height: "40", url: avatar_icon(issue.author_email)
      xml.author do |author|
        xml.name issue.author_name
        xml.email issue.author_email
      end
      xml.summary issue.title
    end
  end
end

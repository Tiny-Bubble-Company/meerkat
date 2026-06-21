# frozen_string_literal: true

module DashboardHelper
  def dashboard_nav_link(path, label)
    active = case path
    when :tasks then controller_path == "docs/dashboard/tasks"
    when :runs then controller_path == "docs/dashboard/task_runs"
    else false
    end

    url = case path
    when :tasks then docs_dashboard_tasks_path
    when :runs then docs_dashboard_task_runs_path
    end

    link_to label, url, class: "nav-link#{' active' if active}"
  end

  def dashboard_status_badge(status)
    css = case status.to_s
    when "active", "succeeded", "webhook_delivered" then "dash-badge dash-badge-success"
    when "failed", "webhook_failed" then "dash-badge dash-badge-danger"
    when "running", "pending" then "dash-badge dash-badge-warn"
    when "paused", "completed", "archived" then "dash-badge dash-badge-muted"
    else "dash-badge dash-badge-muted"
    end

    content_tag(:span, status, class: css)
  end

  def dashboard_timestamp(time)
    return "—" unless time

    time.utc.strftime("%Y-%m-%d %H:%M UTC")
  end

  def dashboard_json(data)
    content_tag(:pre, class: "dash-json") do
      content_tag(:code, JSON.pretty_generate(data.is_a?(Hash) ? data : data.as_json))
    end
  end

  def dashboard_pagination(page, per, total)
    return if total <= per

    pages = (total.to_f / per).ceil
    content_tag(:div, class: "dash-pagination") do
      safe_join([
        (link_to("← Prev", url_for(page: page - 1), class: "dash-page-link") if page > 1),
        content_tag(:span, "Page #{page} of #{pages} (#{total} total)", class: "dash-page-info"),
        (link_to("Next →", url_for(page: page + 1), class: "dash-page-link") if page < pages)
      ].compact)
    end
  end

  def dashboard_webhook_status(event)
    case event.event_type
    when "webhook_delivered"
      dashboard_status_badge("delivered") + " #{event.webhook_response_code}"
    when "webhook_failed"
      dashboard_status_badge("failed") + tag.span(" #{event.payload['error']}", class: "dash-error-text")
    else
      if event.webhook_delivered_at.present?
        dashboard_status_badge("delivered") + " #{event.webhook_response_code}"
      elsif event.webhook_response_code.to_i.zero? && event.webhook_url.present?
        dashboard_status_badge("failed")
      else
        dashboard_status_badge(event.event_type)
      end
    end
  end

  def dashboard_task_tab_class(active_tab, tab)
    "dash-tab#{' dash-tab--active' if active_tab == tab}"
  end

  def dashboard_webhook_label(task)
    if task.uses_default_webhook?
      safe_join([
        content_tag(:span, "default", class: "dash-badge dash-badge-muted"),
        tag.span(" → #{task.resolved_output_webhook}", class: "dash-muted-inline")
      ])
    else
      task.output_webhook
    end
  end
end

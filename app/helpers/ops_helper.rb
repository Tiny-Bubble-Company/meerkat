# frozen_string_literal: true

module OpsHelper
  def ops_nav_link(path, label)
    active = case path
    when :root then controller_name == "dashboard"
    when :users then controller_name == "users"
    when :tasks then controller_name == "tasks"
    when :runs then controller_name == "task_runs"
    when :webhooks then controller_name == "webhook_deliveries"
    else false
    end

    url = case path
    when :root then ops_root_path
    when :users then ops_users_path
    when :tasks then ops_tasks_path
    when :runs then ops_task_runs_path
    when :webhooks then ops_webhook_deliveries_path
    end

    link_to label, url, class: "nav-link#{' active' if active}"
  end

  def ops_status_badge(status)
    css = case status.to_s
    when "active", "succeeded", "webhook_delivered" then "badge-success"
    when "failed", "webhook_failed" then "badge-danger"
    when "running", "pending" then "badge-warn"
    when "paused", "completed", "archived" then "badge-muted"
    else "badge-muted"
    end

    content_tag(:span, status, class: "badge #{css}")
  end

  def ops_json(data)
    content_tag(:pre, class: "json-block") do
      content_tag(:code, JSON.pretty_generate(data.is_a?(Hash) ? data : data.as_json))
    end
  end

  def ops_pagination(page, per, total)
    return if total <= per

    pages = (total.to_f / per).ceil
    content_tag(:div, class: "pagination") do
      safe_join([
        (link_to("← Prev", url_for(page: page - 1), class: "page-link") if page > 1),
        content_tag(:span, "Page #{page} of #{pages} (#{total} total)", class: "page-info"),
        (link_to("Next →", url_for(page: page + 1), class: "page-link") if page < pages)
      ].compact)
    end
  end

  def ops_timestamp(time)
    return "—" unless time

    content_tag(:time, time.utc.strftime("%Y-%m-%d %H:%M:%S UTC"), datetime: time.iso8601, title: time.iso8601)
  end

  def ops_webhook_status(event)
    case event.event_type
    when "webhook_delivered"
      ops_status_badge("delivered") + " #{event.webhook_response_code}"
    when "webhook_failed"
      ops_status_badge("failed") + tag.span(" #{event.payload['error']}", class: "error-text")
    else
      if event.webhook_delivered_at.present?
        ops_status_badge("delivered") + " #{event.webhook_response_code}"
      elsif event.webhook_response_code.to_i.zero?
        ops_status_badge("failed")
      else
        ops_status_badge(event.event_type)
      end
    end
  end
end

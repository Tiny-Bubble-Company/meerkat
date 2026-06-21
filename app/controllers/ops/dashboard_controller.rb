# frozen_string_literal: true

module Ops
  class DashboardController < ApplicationController
    def index
      @stats = {
        users: Customer.count,
        tasks: Task.count,
        runs: TaskRun.count,
        webhook_events: TaskEvent.where(event_type: %w[webhook_delivered webhook_failed]).count,
        failed_runs: TaskRun.where(status: "failed").count,
        failed_webhooks: TaskEvent.where(event_type: "webhook_failed").count
      }

      @recent_runs = TaskRun.includes(:task).recent.limit(10)
      @recent_webhooks = TaskEvent.includes(:task, :task_run)
        .where(event_type: %w[webhook_delivered webhook_failed])
        .recent
        .limit(10)
    end
  end
end

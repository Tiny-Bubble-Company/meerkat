# frozen_string_literal: true

module Ops
  class WebhookDeliveriesController < ApplicationController
    WEBHOOK_EVENT_TYPES = %w[webhook_delivered webhook_failed run_completed run_failed].freeze

    def index
      scope = TaskEvent.includes(:task, :task_run)
        .where(event_type: params[:event_type].presence || WEBHOOK_EVENT_TYPES)
        .order(created_at: :desc)

      scope = scope.where("webhook_response_code = ?", params[:response_code]) if params[:response_code].present?
      scope = scope.where(task_id: params[:task_id]) if params[:task_id].present?

      if params[:delivery_status] == "success"
        scope = scope.where(event_type: "webhook_delivered")
      elsif params[:delivery_status] == "failed"
        scope = scope.where(event_type: "webhook_failed")
      end

      @deliveries, @page, @per, @total = paginate(scope)
    end

    def show
      @delivery = TaskEvent.includes(:task, :task_run).find(params[:id])
      @related = TaskEvent.where(task_id: @delivery.task_id, task_run_id: @delivery.task_run_id)
        .where(event_type: %w[webhook_delivered webhook_failed])
        .recent
    end
  end
end

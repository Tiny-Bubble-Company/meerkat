# frozen_string_literal: true

module Ops
  class TasksController < ApplicationController
    def index
      scope = Task.includes(:customer).order(created_at: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where(task_type: params[:task_type]) if params[:task_type].present?
      scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
      @tasks, @page, @per, @total = paginate(scope)
    end

    def show
      @task = Task.includes(:customer).find(params[:id])
      @runs = @task.task_runs.recent.limit(20)
      @events = @task.task_events.recent.limit(20)
    end
  end
end

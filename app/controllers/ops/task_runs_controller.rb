# frozen_string_literal: true

module Ops
  class TaskRunsController < ApplicationController
    def index
      scope = TaskRun.includes(task: :customer).order(created_at: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where(task_id: params[:task_id]) if params[:task_id].present?
      @runs, @page, @per, @total = paginate(scope)
    end

    def show
      @run = TaskRun.includes(task: :customer).find(params[:id])
      @events = @run.task_events.recent
    end
  end
end

# frozen_string_literal: true

module Docs
  module Dashboard
    class TaskRunsController < Docs::ApplicationController
      def index
        scope = TaskRun.joins(:task).where(tasks: { customer_id: current_customer.id }).includes(:task).order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(task_id: params[:task_id]) if params[:task_id].present?
        @runs, @page, @per, @total = paginate(scope)
      end

      def show
        @run = TaskRun.joins(:task).where(tasks: { customer_id: current_customer.id }).includes(:task).find(params[:id])
        @events = @run.task_events.recent
      end
    end
  end
end

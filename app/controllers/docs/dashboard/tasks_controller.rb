# frozen_string_literal: true

module Docs
  module Dashboard
    class TasksController < Docs::ApplicationController
      def index
        scope = current_customer.tasks.order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(task_type: params[:task_type]) if params[:task_type].present?
        @tasks, @page, @per, @total = paginate(scope)
        @task = Task.new(task_type: "one_off", output_webhook: default_webhook_value)
      end

      def show
        @task = current_customer.tasks.find(params[:id])
        @tab = %w[runs events].include?(params[:tab]) ? params[:tab] : "runs"
        @runs = @task.task_runs.recent.limit(50)
        @events = @task.task_events.recent.limit(50)
      end

      def create
        task = Tasks::Create.call(**task_create_params, customer: current_customer)
        redirect_to docs_dashboard_task_path(task), notice: "Task created."
      rescue Tasks::Create::Error => e
        redirect_to docs_dashboard_tasks_path, alert: e.message
      end

      def run
        task = current_customer.tasks.find(params[:id])
        Tasks::Run.call(task: task, async: true)
        redirect_to docs_dashboard_task_path(task, tab: "runs"), notice: "Run enqueued."
      rescue Tasks::Run::Error => e
        redirect_to docs_dashboard_task_path(task, tab: "runs"), alert: e.message
      end

      private

      def default_webhook_value
        current_customer.default_webhook_configured? ? Tasks::WebhookTarget::DEFAULT_TOKEN : ""
      end

      def task_create_params
        permitted = params.require(:task).permit(
          :task_type, :description, :frequency, :output_webhook, :output_format, :run_immediately,
          :input_params_json
        )

        {
          task_type: permitted[:task_type],
          description: permitted[:description],
          frequency: permitted[:frequency],
          output_webhook: permitted[:output_webhook],
          output_format: permitted[:output_format],
          run_immediately: ActiveModel::Type::Boolean.new.cast(permitted[:run_immediately]),
          input_params: parse_input_params!(permitted[:input_params_json])
        }
      end

      def parse_input_params!(raw)
        text = raw.to_s.strip
        raise Tasks::Create::Error, "input_params is required" if text.blank?

        parsed = JSON.parse(text)
        raise Tasks::Create::Error, "input_params must be a JSON object" unless parsed.is_a?(Hash)

        parsed
      rescue JSON::ParserError
        raise Tasks::Create::Error, "input_params must be valid JSON"
      end
    end
  end
end

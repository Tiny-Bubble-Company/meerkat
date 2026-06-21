# frozen_string_literal: true

module Api
  module V1
    class TasksController < Api::BaseController
      before_action :set_task, only: [ :show, :update, :destroy, :run, :runs, :events, :pause, :resume ]

      def index
        result = Tasks::List.call(
          customer: current_customer,
          task_type: params[:task_type],
          status: params[:status],
          include_archived: ActiveModel::Type::Boolean.new.cast(params[:include_archived]),
          limit: index_limit,
          offset: index_offset
        )

        render_collection(
          result.records.map { |task| TaskSerializer.render(task) },
          meta: {
            limit: result.limit,
            offset: result.offset,
            count: result.records.size,
            total: result.total
          }
        )
      end

      def show
        render_resource(@task, include_state: true)
      end

      def create
        task = Tasks::Create.call(**create_attributes, customer: current_customer)

        render_resource(task, status: :created)
      rescue Tasks::Create::Error => e
        render_error(e.message, status: :unprocessable_entity, title: "Invalid Task")
      rescue FrequencyParser::Error => e
        render_error(e.message, status: :unprocessable_entity, title: "Invalid Frequency")
      rescue ActiveRecord::RecordInvalid => e
        render_validation_errors(e.record)
      end

      def update
        task = if request.put?
          Tasks::Replace.call(task: @task, **replace_attributes)
        else
          Tasks::Update.call(task: @task, **update_attributes)
        end

        render_resource(task)
      rescue Tasks::Update::Error, Tasks::Replace::Error => e
        render_error(e.message, status: :unprocessable_entity, title: "Update Failed")
      rescue ActiveRecord::RecordInvalid => e
        render_validation_errors(e.record)
      end

      def destroy
        Tasks::Destroy.call(
          task: @task,
          permanent: ActiveModel::Type::Boolean.new.cast(params[:permanent])
        )

        head :no_content
      end

      def run
        task_run = Tasks::Run.call(task: @task, async: run_async?)

        render_run(task_run)
      rescue Tasks::Run::Error => e
        render_error(e.message, status: :unprocessable_entity, title: "Run Failed")
      end

      def pause
        @task.pause!
        render_resource(@task)
      rescue Tasks::Error => e
        render_error(e.message, status: :unprocessable_entity, title: "Pause Failed")
      end

      def resume
        @task.resume!
        ExecuteTaskJob.perform_later(@task.id)
        render_resource(@task)
      rescue Tasks::Error => e
        render_error(e.message, status: :unprocessable_entity, title: "Resume Failed")
      end

      def runs
        limit = runs_limit
        runs = @task.task_runs.recent.limit(limit)
        render_collection(
          runs.map { |run| TaskRunSerializer.render(run) },
          meta: { limit: limit, count: runs.size, task_id: @task.id }
        )
      end

      def events
        limit = events_limit
        events = @task.task_events.recent.limit(limit)
        render_collection(
          events.map { |event| TaskEventSerializer.render(event) },
          meta: { limit: limit, count: events.size, task_id: @task.id }
        )
      end

      private

      def set_task
        @task = current_customer.tasks.find(params[:id])
      end

      def create_attributes
        permitted = params.require(:task).permit(
          :task_type,
          :description,
          :frequency,
          :output_webhook,
          :output_format,
          :run_immediately,
          input_params: {},
          metadata: {}
        )

        attrs = {
          task_type: permitted[:task_type] || "recurring",
          description: permitted[:description],
          input_params: permitted[:input_params] || {},
          frequency: permitted[:frequency],
          output_webhook: permitted[:output_webhook],
          output_format: permitted[:output_format],
          metadata: permitted[:metadata] || {}
        }
        attrs[:run_immediately] = cast_boolean(permitted[:run_immediately]) unless permitted[:run_immediately].nil?
        attrs
      end

      def update_attributes
        params.require(:task).permit(
          :description,
          :frequency,
          :output_webhook,
          :output_format,
          :status,
          input_params: {},
          metadata: {}
        ).to_h.symbolize_keys
      end

      def replace_attributes
        params.require(:task).permit(
          :description,
          :frequency,
          :output_webhook,
          :output_format,
          :status,
          input_params: {},
          metadata: {}
        ).to_h.symbolize_keys
      end

      def cast_boolean(value)
        return nil if value.nil?

        ActiveModel::Type::Boolean.new.cast(value)
      end

      def index_limit
        [ params.fetch(:limit, 50).to_i, 200 ].min
      end

      def index_offset
        [ params.fetch(:offset, 0).to_i, 0 ].max
      end

      def runs_limit
        [ params.fetch(:limit, 20).to_i, 100 ].min
      end

      def events_limit
        [ params.fetch(:limit, 50).to_i, 200 ].min
      end

      def run_async?
        ActiveModel::Type::Boolean.new.cast(params.fetch(:async, true))
      end
    end
  end
end

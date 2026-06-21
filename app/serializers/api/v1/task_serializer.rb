# frozen_string_literal: true

module Api
  module V1
    module TaskSerializer
      module_function

      def render(task, include_state: false)
        payload = {
          id: task.id,
          task_type: task.task_type,
          description: task.description,
          input_params: task.input_params,
          frequency: task.frequency,
          frequency_seconds: task.frequency_seconds,
          output_webhook: task.output_webhook,
          output_format: task.output_format,
          status: task.status,
          last_run_at: task.last_run_at,
          next_run_at: task.next_run_at,
          run_count: task.run_count,
          consecutive_failures: task.consecutive_failures,
          metadata: task.metadata,
          created_at: task.created_at,
          updated_at: task.updated_at
        }
        payload[:last_known_state] = task.last_known_state if include_state
        payload
      end
    end
  end
end

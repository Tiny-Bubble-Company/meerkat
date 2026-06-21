# frozen_string_literal: true

module Api
  module V1
    module TaskRunSerializer
      module_function

      def render(run)
        {
          id: run.id,
          task_id: run.task_id,
          status: run.status,
          output: run.output,
          structured_output: run.structured_output,
          error: run.error,
          usage: run.usage,
          change_detected: run.change_detected,
          started_at: run.started_at,
          finished_at: run.finished_at,
          created_at: run.created_at
        }
      end
    end
  end
end

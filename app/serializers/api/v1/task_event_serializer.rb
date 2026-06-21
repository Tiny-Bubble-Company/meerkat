# frozen_string_literal: true

module Api
  module V1
    module TaskEventSerializer
      module_function

      def render(event)
        {
          id: event.id,
          task_id: event.task_id,
          task_run_id: event.task_run_id,
          event_type: event.event_type,
          payload: event.payload,
          webhook_url: event.webhook_url,
          webhook_response_code: event.webhook_response_code,
          webhook_delivered_at: event.webhook_delivered_at,
          created_at: event.created_at
        }
      end
    end
  end
end

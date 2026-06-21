# frozen_string_literal: true

module Tasks
  class Report
    def self.call(task:, event_type:, payload:, run: nil, deliver_webhook: false)
      new(task:, run:, event_type:, payload:, deliver_webhook:).call
    end

    def initialize(task:, event_type:, payload:, run: nil, deliver_webhook: false)
      @task = task
      @run = run
      @event_type = event_type
      @payload = payload
      @deliver_webhook = deliver_webhook
    end

    def call
      event = @task.task_events.create!(
        task_run: @run,
        event_type: @event_type,
        payload: @payload,
        webhook_url: @task.output_webhook
      )

      DeliverWebhookJob.perform_later(event.id) if @deliver_webhook && @task.output_webhook.present?

      event
    end
  end
end

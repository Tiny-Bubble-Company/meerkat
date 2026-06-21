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
      target = Tasks::WebhookTarget.for(@task)

      event = @task.task_events.create!(
        task_run: @run,
        event_type: @event_type,
        payload: @payload,
        webhook_url: target[:url]
      )

      DeliverWebhookJob.perform_later(event.id) if @deliver_webhook && target[:configured]

      event
    end
  end
end

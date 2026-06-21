# frozen_string_literal: true

module Webhooks
  class Deliver
    def self.call(event:)
      new(event:).call
    end

    def initialize(event:)
      @event = event
      @url = event.webhook_url
    end

    def call
      return unless @url.present?

      target = Tasks::WebhookTarget.for(@event.task)

      response = connection.post(@url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["User-Agent"] = "Meerkat/1.0"
        req.headers["X-Meerkat-Event"] = @event.event_type
        target[:headers].each { |key, value| req.headers[key] = value }
        req.body = payload.to_json
      end

      @event.update!(
        webhook_response_code: response.status,
        webhook_delivered_at: Time.current
      )

      TaskEvent.create!(
        task: @event.task,
        task_run: @event.task_run,
        event_type: "webhook_delivered",
        payload: {
          source_event_id: @event.id,
          response_code: response.status
        },
        webhook_url: @url,
        webhook_response_code: response.status,
        webhook_delivered_at: Time.current
      )

      response
    rescue StandardError => e
      @event.update!(webhook_response_code: 0)

      TaskEvent.create!(
        task: @event.task,
        task_run: @event.task_run,
        event_type: "webhook_failed",
        payload: {
          source_event_id: @event.id,
          error: e.message
        },
        webhook_url: @url
      )

      raise
    end

    private

    def payload
      Webhooks::PayloadFormatter.call(
        event: @event,
        format: OutputFormat.effective(@event.task.output_format)
      )
    end

    def connection
      Faraday.new do |f|
        f.options.timeout = ENV.fetch("MEERKAT_WEBHOOK_TIMEOUT", 15).to_i
        f.options.open_timeout = 5
        f.adapter Faraday.default_adapter
      end
    end
  end
end

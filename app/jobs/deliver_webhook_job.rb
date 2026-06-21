# frozen_string_literal: true

class DeliverWebhookJob < ApplicationJob
  queue_as :webhooks

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(task_event_id)
    event = TaskEvent.find(task_event_id)
    Webhooks::Deliver.call(event: event)
  end
end

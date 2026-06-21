# frozen_string_literal: true

class TaskEvent < ApplicationRecord
  EVENT_TYPES = %w[
    task_registered
    task_updated
    task_archived
    run_started
    run_completed
    run_failed
    status_changed
    webhook_delivered
    webhook_failed
  ].freeze

  belongs_to :task
  belongs_to :task_run, optional: true

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :payload, presence: true

  scope :recent, -> { order(created_at: :desc) }
end

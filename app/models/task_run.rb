# frozen_string_literal: true

class TaskRun < ApplicationRecord
  STATUSES = %w[pending running succeeded failed].freeze

  belongs_to :task
  has_many :task_events, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def mark_running!
    update!(status: "running", started_at: Time.current)
  end

  def mark_succeeded!(output:, structured_output:, usage:, change_detected:)
    update!(
      status: "succeeded",
      output: output,
      structured_output: structured_output,
      usage: usage,
      change_detected: change_detected,
      finished_at: Time.current,
      error: nil
    )
  end

  def mark_failed!(error:)
    update!(
      status: "failed",
      error: error,
      finished_at: Time.current
    )
  end
end

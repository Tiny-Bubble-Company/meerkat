# frozen_string_literal: true

class Task < ApplicationRecord
  TASK_TYPES = %w[recurring one_off].freeze
  STATUSES = %w[active paused completed archived failed].freeze

  belongs_to :customer, optional: true
  has_many :task_runs, dependent: :destroy
  has_many :task_events, dependent: :destroy

  validates :description, presence: true
  validates :task_type, inclusion: { in: TASK_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :input_params, presence: true
  validates :output_webhook, presence: true
  validates :frequency, presence: true, if: :recurring?
  validates :frequency_seconds, numericality: { greater_than: 0 }, allow_nil: true
  validates :frequency_seconds, presence: true, if: :recurring?
  validate :output_format_length

  scope :recurring, -> { where(task_type: "recurring") }
  scope :one_off, -> { where(task_type: "one_off") }
  scope :active, -> { where(status: "active") }
  scope :due, -> { recurring.active.where("next_run_at <= ?", Time.current) }

  def recurring?
    task_type == "recurring"
  end

  def one_off?
    task_type == "one_off"
  end

  def pause!
    raise Tasks::Error, "Only recurring tasks can be paused" unless recurring?

    update!(status: "paused")
  end

  def resume!
    raise Tasks::Error, "Only recurring tasks can be resumed" unless recurring?

    update!(status: "active", next_run_at: Time.current)
  end

  def schedule_next_run!(from: Time.current)
    raise Tasks::Error, "One-off tasks are not scheduled" unless recurring?

    update!(next_run_at: from + frequency_seconds.seconds)
  end

  def runnable?
    active? && !task_runs.exists?(status: "running")
  end

  def active?
    status == "active"
  end

  def custom_output_format_instruction?
    OutputFormat.custom_instruction?(output_format)
  end

  private

  def output_format_length
    OutputFormat.validate!(output_format)
  rescue ArgumentError => e
    errors.add(:output_format, e.message)
  end
end

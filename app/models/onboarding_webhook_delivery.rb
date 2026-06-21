# frozen_string_literal: true

class OnboardingWebhookDelivery < ApplicationRecord
  belongs_to :customer

  validates :payload, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.latest_for_run(customer:, task_run_id:)
    return none unless task_run_id

    where(customer: customer, task_run_id: task_run_id).recent
  end
end

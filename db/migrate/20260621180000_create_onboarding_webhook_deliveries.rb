# frozen_string_literal: true

class CreateOnboardingWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :onboarding_webhook_deliveries do |t|
      t.references :customer, null: false, foreign_key: true
      t.bigint :task_run_id
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :onboarding_webhook_deliveries, [ :customer_id, :task_run_id ]
    add_index :onboarding_webhook_deliveries, [ :customer_id, :created_at ]
  end
end

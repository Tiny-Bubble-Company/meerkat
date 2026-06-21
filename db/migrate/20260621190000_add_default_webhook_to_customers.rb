# frozen_string_literal: true

class AddDefaultWebhookToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :default_output_webhook, :string
    add_column :customers, :default_webhook_headers, :jsonb, default: {}, null: false
  end
end

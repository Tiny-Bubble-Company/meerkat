class CreateMonitorEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_events do |t|
      t.references :monitor_task, null: false, foreign_key: true
      t.references :monitor_run, null: true, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :webhook_url
      t.integer :webhook_response_code
      t.datetime :webhook_delivered_at

      t.timestamps
    end

    add_index :monitor_events, :event_type
    add_index :monitor_events, [ :monitor_task_id, :created_at ]
  end
end

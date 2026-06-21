class CreateMonitorTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_tasks do |t|
      t.text :description, null: false
      t.jsonb :input_params, null: false, default: {}
      t.string :frequency, null: false
      t.integer :frequency_seconds, null: false
      t.string :output_webhook
      t.string :status, null: false, default: "active"
      t.jsonb :last_known_state, null: false, default: {}
      t.datetime :last_run_at
      t.datetime :next_run_at
      t.jsonb :metadata, null: false, default: {}
      t.integer :run_count, null: false, default: 0
      t.integer :consecutive_failures, null: false, default: 0

      t.timestamps
    end

    add_index :monitor_tasks, :status
    add_index :monitor_tasks, :next_run_at
    add_index :monitor_tasks, [ :status, :next_run_at ]
  end
end

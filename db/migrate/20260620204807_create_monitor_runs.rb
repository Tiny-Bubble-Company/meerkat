class CreateMonitorRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_runs do |t|
      t.references :monitor_task, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.text :output
      t.jsonb :structured_output, null: false, default: {}
      t.text :error
      t.jsonb :usage, null: false, default: {}
      t.boolean :change_detected, null: false, default: false
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :monitor_runs, :status
    add_index :monitor_runs, [:monitor_task_id, :created_at]
  end
end

class RedesignTasksWithTaskType < ActiveRecord::Migration[8.1]
  def change
    rename_table :monitor_tasks, :tasks
    rename_table :monitor_runs, :task_runs
    rename_table :monitor_events, :task_events

    rename_column :task_runs, :monitor_task_id, :task_id
    rename_column :task_events, :monitor_task_id, :task_id
    rename_column :task_events, :monitor_run_id, :task_run_id

    add_column :tasks, :task_type, :string, null: false, default: "recurring"

    change_column_null :tasks, :frequency, true
    change_column_null :tasks, :frequency_seconds, true

    add_index :tasks, :task_type
    add_index :tasks, [ :task_type, :status ]
    add_index :tasks, [ :task_type, :status, :next_run_at ], name: "index_tasks_on_type_status_and_next_run_at"
  end
end

class AddDeveloperToTasks < ActiveRecord::Migration[8.1]
  def change
    add_reference :tasks, :developer, null: true, foreign_key: true
    add_index :tasks, [:developer_id, :status]
  end
end

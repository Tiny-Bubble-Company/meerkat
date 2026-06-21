class AddOutputFormatToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :output_format, :string
  end
end

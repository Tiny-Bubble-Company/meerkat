class RenameDevelopersToCustomers < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :api_keys, :developers
    remove_foreign_key :tasks, :developers

    rename_table :developers, :customers

    rename_column :api_keys, :developer_id, :customer_id
    rename_column :tasks, :developer_id, :customer_id

    add_foreign_key :api_keys, :customers
    add_foreign_key :tasks, :customers
  end
end

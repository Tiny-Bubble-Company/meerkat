class CreateDevelopers < ActiveRecord::Migration[8.1]
  def change
    create_table :developers do |t|
      t.string :email, null: false
      t.string :name
      t.string :company

      t.timestamps
    end

    add_index :developers, :email, unique: true
  end
end

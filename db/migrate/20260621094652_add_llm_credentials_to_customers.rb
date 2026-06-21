class AddLlmCredentialsToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :llm_provider, :string
    add_column :customers, :llm_api_key_ciphertext, :text
    add_column :customers, :llm_model, :string
  end
end

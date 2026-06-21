class AddOnboardingCompletedAtToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :onboarding_completed_at, :datetime
  end
end

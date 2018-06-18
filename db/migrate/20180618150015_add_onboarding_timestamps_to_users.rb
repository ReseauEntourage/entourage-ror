class AddOnboardingTimestampsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :first_sign_in_at, :datetime
    add_column :users, :onboarding_sequence_start_at, :datetime
  end
end

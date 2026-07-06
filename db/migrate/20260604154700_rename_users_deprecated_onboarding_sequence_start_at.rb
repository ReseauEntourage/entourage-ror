class RenameUsersDeprecatedOnboardingSequenceStartAt < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :onboarding_sequence_start_at, :old_onboarding_sequence_start_at
  end
end


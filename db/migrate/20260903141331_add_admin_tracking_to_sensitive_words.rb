class AddAdminTrackingToSensitiveWords < ActiveRecord::Migration[7.1]
  def change
    add_column :sensitive_words, :created_at, :datetime
    add_column :sensitive_words, :updated_at, :datetime
    add_column :sensitive_words, :created_by_id, :integer

    add_column :sensitive_words_checks, :checked_by_id, :integer
  end
end

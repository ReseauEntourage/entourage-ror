class AddUserInterestIdsToUserSmalltalks < ActiveRecord::Migration[6.1]
  def change
    add_column :user_smalltalks, :user_interest_ids, :jsonb, default: []
  end
end

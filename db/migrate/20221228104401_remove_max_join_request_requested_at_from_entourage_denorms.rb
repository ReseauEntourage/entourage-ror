class RemoveMaxJoinRequestRequestedAtFromEntourageDenorms < ActiveRecord::Migration[5.2]
  def up
    remove_column :entourage_denorms, :max_join_request_requested_at
  end

  def down
    add_column :entourage_denorms, :max_join_request_requested_at, :datetime
  end
end

class AddInstanceTypeCreatedAtIndexToUserReactions < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :user_reactions, [:instance_type, :created_at], if_not_exists: true
  end
end

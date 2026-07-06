class AddInstanceTypeCreatedAtIndexToUserReactions < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :user_reactions, [:instance_type, :created_at],
      name: 'index_user_reactions_on_instance_type_and_created_at',
      algorithm: :concurrently,
      if_not_exists: true
  end
end

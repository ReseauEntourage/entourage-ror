class AddlastSignInAtToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :last_sign_in_at, :datetime, null: true
  end
end

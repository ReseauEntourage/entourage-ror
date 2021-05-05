class AllowDuplicateEmailForUser < ActiveRecord::Migration[4.2]
  def change
    remove_index "users", ["email"]
  end
end

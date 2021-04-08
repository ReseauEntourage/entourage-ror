class DeleteUserNewsfeeds < ActiveRecord::Migration[4.2]
  def change
    drop_table :user_newsfeeds
  end
end

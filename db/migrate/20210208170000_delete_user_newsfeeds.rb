class DeleteUserNewsfeeds < ActiveRecord::Migration
  def change
    drop_table :user_newsfeeds
  end
end

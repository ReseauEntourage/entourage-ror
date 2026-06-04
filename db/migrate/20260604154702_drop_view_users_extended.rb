class DropViewUsersExtended < ActiveRecord::Migration[7.1]
  def up
    execute 'DROP VIEW IF EXISTS users_extended;'
  end
end

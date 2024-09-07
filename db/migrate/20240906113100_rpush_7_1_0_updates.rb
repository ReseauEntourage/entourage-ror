class Rpush710Updates < ActiveRecord::Migration[6.1]
  def self.up
    add_column :rpush_apps, :firebase_project_id, :string
    add_column :rpush_apps, :json_key, :text
  end

  def self.down
    remove_column :rpush_apps, :firebase_project_id
    remove_column :rpush_apps, :json_key
  end
end


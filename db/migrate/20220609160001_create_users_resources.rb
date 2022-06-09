class CreateUsersResources < ActiveRecord::Migration[5.2]
  def up
    create_table :users_resources do |t|
      t.belongs_to :user, index: true
      t.belongs_to :resource, index: true
      t.boolean :displayed, default: false
      t.timestamps
    end
  end

  def down
    drop_table :users_resources
  end
end


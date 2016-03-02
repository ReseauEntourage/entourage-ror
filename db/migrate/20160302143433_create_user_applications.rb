class CreateUserApplications < ActiveRecord::Migration
  def change
    create_table :user_applications do |t|
      t.string :push_token, null: false
      t.string :device_os,  null: false
      t.string :version,    null: false
      t.integer :user_id,   null: false

      t.timestamps null: false
    end

    add_index :user_applications, [:user_id, :device_os, :version], unique: true
  end
end

class CreateUsersAppetences < ActiveRecord::Migration
  def change
    create_table :users_appetences do |t|
      t.integer :user_id,                 null: false
      t.integer :appetence_social,        null: false, default: 0
      t.integer :appetence_mat_help,      null: false, default: 0
      t.integer :appetence_non_mat_help,  null: false, default: 0
      t.float :avg_dist,                  null: false, default: 150

      t.timestamps null: false
    end

    add_index :users_appetences, :user_id, unique: true
  end
end

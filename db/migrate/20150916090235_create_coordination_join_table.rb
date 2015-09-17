class CreateCoordinationJoinTable < ActiveRecord::Migration
  def change
    create_table :coordination, id: false do |t|
      t.integer :user_id
      t.integer :organization_id
   end
  end
end

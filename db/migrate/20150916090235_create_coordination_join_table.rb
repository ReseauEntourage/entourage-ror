class CreateCoordinationJoinTable < ActiveRecord::Migration[4.2]
  def change
    create_table :coordination, id: false do |t|
      t.integer :user_id
      t.integer :organization_id
   end
  end
end

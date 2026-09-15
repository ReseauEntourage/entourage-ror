class CreateUserSegments < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:user_segments)

    create_table :user_segments do |t|
      t.integer :user_id, null: false
      t.string :engagement_segment
      t.string :engagement_sub_segment
      t.datetime :segment_computed_at, null: false
    end

    add_index :user_segments, :user_id, unique: true, name: "index_user_segments_on_user_id"
  end
end

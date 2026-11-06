class CreateUserSegmentHistory < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:user_segment_history)

    create_table :user_segment_history do |t|
      t.integer :user_id, null: false
      t.string :engagement_segment
      t.string :engagement_sub_segment
      t.date :valid_from, null: false
      t.date :valid_to
      t.datetime :computed_at, null: false
    end

    add_index :user_segment_history,
              [:user_id, :valid_from],
              unique: true,
              name: "index_user_segment_history_on_user_id_and_valid_from"

    # Enforces at most one open (valid_to IS NULL) row per user, and makes
    # "find the user's current segment history entry" a fast lookup.
    add_index :user_segment_history,
              :user_id,
              unique: true,
              where: "valid_to IS NULL",
              name: "index_user_segment_history_on_user_id_where_open"
  end
end

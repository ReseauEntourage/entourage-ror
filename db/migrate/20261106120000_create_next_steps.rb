class CreateNextSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :next_steps do |t|
      t.integer :user_id, null: false
      # outing, neighborhood, action, content_path, smalltalk, poi, post_message, become_ambassador
      t.string :kind, null: false
      t.string :target_type
      t.integer :target_id
      # the 3 resources of a content_path
      t.jsonb :target_ids, null: false, default: []
      # segment or need
      t.string :mode, null: false
      # the solicitation the suggestion answers, in need mode
      t.integer :need_id
      t.string :segment
      t.string :sub_segment
      # computed, assumed_new, assumed_returning or team
      t.string :segment_source, null: false
      t.string :profile
      t.float :score
      t.jsonb :score_components, null: false, default: {}
      t.string :reason_codes, array: true, null: false, default: []
      # active, realised, ignored, expired or closed
      t.string :status, null: false, default: 'active'
      t.datetime :first_displayed_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :realised_at
      t.datetime :ignored_at
      t.datetime :closed_at
      t.timestamps
    end

    add_index :next_steps, :user_id, unique: true, where: "status = 'active'", name: 'index_next_steps_on_active_user_id'
    add_index :next_steps, [:user_id, :kind, :target_type, :target_id], name: 'index_next_steps_on_user_id_and_target'
    add_index :next_steps, [:user_id, :first_displayed_at], name: 'index_next_steps_on_user_id_and_first_displayed_at'
  end
end

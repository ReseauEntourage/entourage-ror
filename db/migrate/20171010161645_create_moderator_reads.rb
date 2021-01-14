class CreateModeratorReads < ActiveRecord::Migration[4.2]
  def change
    create_table :moderator_reads do |t|
      t.integer  :user_id,          null: false
      t.integer  :moderatable_id,   null: false
      t.string   :moderatable_type, null: false
      t.datetime :read_at,          null: false
    end

    add_index :moderator_reads, [:user_id, :moderatable_id, :moderatable_type], name: :index_moderator_reads_on_user_id_and_moderatable
  end
end

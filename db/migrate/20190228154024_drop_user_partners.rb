class DropUserPartners < ActiveRecord::Migration[4.2]
  def up
    drop_table :user_partners
  end

  def down
    create_table 'user_partners', force: :cascade do |t|
      t.integer  'user_id',                    null: false
      t.integer  'partner_id',                 null: false
      t.boolean  'default',    default: false, null: false
      t.datetime 'created_at',                 null: false
      t.datetime 'updated_at',                 null: false
    end

    add_index 'user_partners', ['user_id', 'partner_id'], name: 'index_user_partners_on_user_id_and_partner_id', unique: true, using: :btree
    add_index 'user_partners', ['user_id'], name: 'index_user_partners_on_user_id', where: '"default"', using: :btree
  end
end

class CreateUserModeration < ActiveRecord::Migration[4.2]
  def change
    create_table :user_moderations do |t|
      t.integer :user_id, null: false

      t.string :expectations
      t.string :acquisition_channel
      t.string :content_sent
      t.string :skills

      t.boolean :accepts_event_invitations
      t.boolean :accepts_volunteering_offers
      t.boolean :ambassador
    end

    add_index :user_moderations, :user_id, unique: true
  end
end

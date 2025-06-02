class CreateUserSmalltalks < ActiveRecord::Migration[6.1]
  def change
    create_table :user_smalltalks do |t|
      # relationships
      t.references :user, null: false, foreign_key: true
      t.references :smalltalk, null: true, foreign_key: true

      t.string :uuid_v2, limit: 12

      # user information
      t.integer :user_gender, default: 0 # default: "male"
      t.integer :user_profile, default: 0 # default: "offer_help"
      t.float :user_latitude
      t.float :user_longitude

      # user preferences for smalltalks
      t.integer :match_format, null: false, default: 0 # default: "one"
      t.boolean :match_locality, default: false
      t.boolean :match_gender, default: false
      t.boolean :match_interest, default: false

      # datetimes
      t.datetime :last_match_computation_at
      t.datetime :matched_at
      t.datetime :deleted_at

      t.timestamps null: false

      t.index :uuid_v2, unique: true
    end
  end
end

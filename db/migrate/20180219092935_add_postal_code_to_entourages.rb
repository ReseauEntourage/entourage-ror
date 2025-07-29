class AddPostalCodeToEntourages < ActiveRecord::Migration[4.2]
  def change
    change_table :entourages do |t|
      t.string   'postal_code', limit: 5
      t.string   'country',     limit: 2
    end
    add_index :entourages, [:country, :postal_code]
  end
end

class AddOtherInterestToEntourages < ActiveRecord::Migration[5.2]
  def up
    add_column :entourages, :other_interest, :string
  end

  def down
    remove_column :entourages, :other_interest
  end
end

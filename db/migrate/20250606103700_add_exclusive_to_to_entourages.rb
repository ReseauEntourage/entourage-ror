class AddExclusiveToToEntourages < ActiveRecord::Migration[6.1]
  def change
    add_column :entourages, :exclusive_to, :string, nullable: true, default: nil
  end
end

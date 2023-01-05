class AddHoursAndLanguagesToPois < ActiveRecord::Migration[5.2]
  def up
    add_column :pois, :hours, :string
    add_column :pois, :languages, :string
  end

  def down
    remove_column :pois, :hours
    remove_column :pois, :languages
  end
end


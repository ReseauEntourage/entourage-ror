class AddLangToUsers < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :lang, :string, default: :fr
  end

  def down
    remove_column :users, :lang
  end
end


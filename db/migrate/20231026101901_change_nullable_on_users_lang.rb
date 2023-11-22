class ChangeNullableOnUsersLang < ActiveRecord::Migration[6.1]
  def up
    change_column_null :users, :lang, true
  end

  def down
    change_column_null :users, :lang, false
  end
end


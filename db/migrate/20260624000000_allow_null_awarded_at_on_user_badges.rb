class AllowNullAwardedAtOnUserBadges < ActiveRecord::Migration[7.1]
  def change
    change_column_null :user_badges, :awarded_at, true
  end
end

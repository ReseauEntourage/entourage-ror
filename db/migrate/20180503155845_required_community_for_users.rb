class RequiredCommunityForUsers < ActiveRecord::Migration[4.2]
  def up
    User.where(community: nil).update_all(community: 'entourage')
    change_column_null :users, :community, false
  end

  def down
    change_column_null :users, :community, true
  end
end

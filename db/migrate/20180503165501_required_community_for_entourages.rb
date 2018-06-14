class RequiredCommunityForEntourages < ActiveRecord::Migration
  def up
    Entourage.where(community: nil).update_all(community: 'entourage')
    change_column_null :entourages, :community, false
  end

  def down
    change_column_null :entourages, :community, true
  end
end

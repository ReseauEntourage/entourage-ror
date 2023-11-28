class AddActivityToModerationAreas < ActiveRecord::Migration[6.1]
  def change
    # the term "activity" has been chosen instead of "active" 
    # "active" might have been understood as "deleted"
    add_column :moderation_areas, :activity, :boolean, null: false, default: false
  end
end

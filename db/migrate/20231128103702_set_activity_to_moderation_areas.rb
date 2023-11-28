class SetActivityToModerationAreas < ActiveRecord::Migration[6.1]
  def change
    ModerationArea.where(departement: [69, 42, 35, 56, 44, 75, 92, 93, 13, 04]).update_all(activity: true)
  end
end

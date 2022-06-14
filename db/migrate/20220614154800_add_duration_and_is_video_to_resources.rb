class AddDurationAndIsVideoToResources < ActiveRecord::Migration[4.2]
  def change
    add_column :resources, :duration, :integer
    add_column :resources, :is_video, :boolean, default: false
  end

  def down
    remove_column :resources, :duration
    remove_column :resources, :is_video
  end
end

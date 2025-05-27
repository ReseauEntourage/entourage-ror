class AddMeetingToSmalltalks < ActiveRecord::Migration[6.1]
  def change
    add_reference :smalltalks, :meeting, foreign_key: true
  end
end

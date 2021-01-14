class AddTimestampsToSimplifiedTourPoints < ActiveRecord::Migration[4.2]
  def change
    add_column(:simplified_tour_points, :created_at, :datetime)
  end
end

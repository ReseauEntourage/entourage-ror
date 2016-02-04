class AddTimestampsToSimplifiedTourPoints < ActiveRecord::Migration
  def change
    add_column(:simplified_tour_points, :created_at, :datetime)
  end
end

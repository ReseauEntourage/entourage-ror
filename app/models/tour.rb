class Tour < ActiveRecord::Base

  validates :tour_type, inclusion: { in: %w(social food other) }
  has_many :tour_points, dependent: :destroy, :order => 'songs.passing_time'
  has_many :encounters


  
end

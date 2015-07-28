class Tour < ActiveRecord::Base

  validates :tour_type, inclusion: { in: %w(health friendly social food other) }
  has_many :tour_points, dependent: :destroy
  has_many :encounters
  enum status: [ :ongoing, :closed ]

end

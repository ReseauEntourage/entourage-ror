class Tour < ActiveRecord::Base

  validates :tour_type, inclusion: { in: %w(social food other) }

end

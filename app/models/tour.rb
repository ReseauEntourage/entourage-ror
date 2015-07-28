class Tour < ActiveRecord::Base

  validates :tour_type, inclusion: { in: %w(health friendly social food other) }
  has_many :tour_points, dependent: :destroy
  has_many :encounters
  enum status: [ :ongoing, :closed ]

  after_update :send_tour_report

  def send_tour_report
    if self.status == "closed" && ! self.email_sent
      MemberMailer.tour_report(self).deliver_later
      self.update_attributes(email_sent: true)
    end
  end

  def get_coordinates_uri_static_map
    coordinates_uri = ""
    self.tour_points.each do |tour_point|
      coordinates_uri += "|#{tour_point.latitude.round(4)},#{tour_point.longitude.round(4)}"
    end
    coordinates_uri
  end
end

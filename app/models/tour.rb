class Tour < ActiveRecord::Base

  validates :tour_type, inclusion: { in: %w(health friendly social food other) }
  has_many :tour_points, dependent: :destroy
  has_many :encounters
  enum status: [ :ongoing, :closed ]
  enum vehicle_type: [ :feet, :car ]
  validates_presence_of :tour_type, :status, :vehicle_type, :user
  belongs_to :user

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
  
  scope :type, -> (type) { where tour_type: type }
  scope :vehicle_type, -> (vehicle_type) { where vehicle_type: vehicle_type }
  
  def status=(value)
    if (value == 'closed' or value == :closed) and status == 'ongoing'
      update_attribute :closed_at, DateTime.now
    end
    super(value)
  end
  
  def duration
    if closed_at.nil?
      Time.now - created_at
    else
      closed_at - created_at
    end
  end
  
end

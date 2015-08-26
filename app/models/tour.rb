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

  def static_map
    if self.tour_points.length > 0 or self.encounters.length > 0
      map = GoogleStaticMap.new(width: 512, height: 512)
      if self.tour_points.length > 0
        tourpoints = MapPolygon.new(:color => '0x0000ff', weight: 5)
        self.tour_points.each do |tp|
          tourpoints.points << MapLocation.new(latitude: tp.latitude, longitude: tp.longitude)
        end
        map.paths << tourpoints
      end
      self.encounters.each do |e|
        map.markers << MapMarker.new(:location => MapLocation.new(latitude: e.latitude, longitude: e.longitude))
      end
      return map
    else
      return EmptyMap.new
    end
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

class EmptyMap
  def url
    ''
  end
end

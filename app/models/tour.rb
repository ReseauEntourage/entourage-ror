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

  def static_map(point_limit: 200, precision: 4)
    if self.tour_points.length > 0 or self.encounters.length > 0
      map = GoogleStaticMap.new(width: 300, height: 300, api_key:ENV["ANDROID_GCM_API_KEY"])
      if self.tour_points.length > 0
        tourpoints = MapPolygon.new(:color => '0x0000ff', weight: 5, polyline: true)
        if self.tour_points.count <= point_limit
          points = self.tour_points
        else
          divider = (self.tour_points.count / point_limit).to_i + 1
          points = []
          self.tour_points.each_with_index do |p,i|
            if i % divider == 0
              points << p
            end
          end
        end
        points.each do |tp|
          tourpoints.points << MapLocation.new(latitude: tp.latitude.round(precision), longitude: tp.longitude.round(precision))
        end
        map.paths << tourpoints
        map.markers << MapMarker.new(label: 'D', color:'green', location: MapLocation.new(latitude: self.tour_points.first.latitude.round(precision), longitude: self.tour_points.first.longitude.round(precision)))
        map.markers << MapMarker.new(label: 'A', color:'red', location: MapLocation.new(latitude: self.tour_points.last.latitude.round(precision), longitude: self.tour_points.last.longitude.round(precision)))
      end
      self.encounters.each_with_index do |e,index|
        map.markers << MapMarker.new(label: (index + 1).to_s, color:'blue', location: MapLocation.new(latitude: e.latitude.round(precision), longitude: e.longitude.round(precision)))
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
  
  def force_close
    update_attributes email_sent: true, status: 'closed'
    last_tour_point = tour_points.last
    update_attributes closed_at: last_tour_point.passing_time if !last_tour_point.nil?
  end
  
  def to_s
    "#{id} - by user #{user} at #{created_at}"
  end
  
end

class EmptyMap
  def url
    ''
  end
end

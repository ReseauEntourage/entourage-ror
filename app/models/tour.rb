class Tour < ActiveRecord::Base

  validates :tour_type, inclusion: { in: %w(medical barehands alimentary) }
  has_many :tour_points, dependent: :delete_all
  has_many :snap_to_road_tour_points, dependent: :delete_all
  has_many :simplified_tour_points, dependent: :delete_all
  has_many :encounters, dependent: :destroy
  enum status: [ :ongoing, :closed ]
  enum vehicle_type: [ :feet, :car ]
  validates_presence_of :tour_type, :status, :vehicle_type, :user
  belongs_to :user
  has_many :tours_users
  has_many :members, through: :tours_users, source: :user

  delegate :organization_name, :organization_description, to: :user

  scope :type, -> (type) { where tour_type: type }
  scope :vehicle_type, -> (vehicle_type) { where vehicle_type: vehicle_type }

  def static_path_map(point_limit: 200, precision: 4)
    if self.tour_points.length > 0
      map = GoogleStaticMap.new(width: 300, height: 300, api_key:ENV["ANDROID_GCM_API_KEY"])
      tourpoints = MapPolygon.new(:color => '0x0000ff', weight: 5, polyline: true)
      points = limited_tour_points point_limit
      points.each do |tp|
        tourpoints.points << MapLocation.new(latitude: tp.latitude.round(precision), longitude: tp.longitude.round(precision))
      end
      if tourpoints.points.length > 1
        map.paths << tourpoints
      end
      map.markers << MapMarker.new(label: 'D', color:'green', location: MapLocation.new(latitude: self.tour_points.first.latitude.round(precision), longitude: self.tour_points.first.longitude.round(precision)))
      map.markers << MapMarker.new(label: 'A', color:'red', location: MapLocation.new(latitude: self.tour_points.last.latitude.round(precision), longitude: self.tour_points.last.longitude.round(precision)))
      return map
    else
      return EmptyMap.new
    end
  end
  
  def static_encounters_map(encounter_limit: 40, precision: 4)
    if self.encounters.length > 0
      map = GoogleStaticMap.new(width: 300, height: 300, api_key:ENV["ANDROID_GCM_API_KEY"])
      
      self.encounters.first(encounter_limit).each_with_index do |e,index|
        label = ApplicationController.helpers.marker_index(index)
        map.markers << MapMarker.new(label: label, color:'blue', location: MapLocation.new(latitude: e.latitude.round(precision), longitude: e.longitude.round(precision)))
      end
      
      return map
    else
      return EmptyMap.new
    end
  end

  def duration
    if closed_at.nil?
      (Time.now - created_at).to_i
    else
      (closed_at - created_at).to_i
    end
  end
  
  def force_close
    update(status: :closed, closed_at: tour_points.last.try(:passing_time) || DateTime.now)
  end

  def closed?
    status=="closed"
  end
  
  def to_s
    "#{id} - by user #{user} at #{created_at}"
  end

  private

  #TODO: remove this method and use simplified tour points instead
  def limited_tour_points(point_limit)
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
    points
  end

end

class EmptyMap
  def url
    ''
  end
end

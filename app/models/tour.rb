class Tour < ActiveRecord::Base
  include FeedsConcern

  TOUR_TYPES=%w(medical barehands alimentary)

  validates :tour_type, inclusion: { in: TOUR_TYPES }
  has_many :tour_points, dependent: :delete_all
  has_many :simplified_tour_points, dependent: :delete_all
  has_many :encounters, dependent: :destroy
  enum status: [ :ongoing, :closed, :freezed ]
  enum vehicle_type: [ :feet, :car ]
  validates_presence_of :tour_type, :status, :vehicle_type, :user
  belongs_to :user
  has_many :join_requests, as: :joinable, dependent: :destroy
  has_many :members, through: :join_requests, source: :user
  has_many :chat_messages, as: :messageable, dependent: :destroy
  has_many :entourage_invitations, as: :invitable, dependent: :destroy

  delegate :organization_name, :organization_description, to: :user

  scope :type, -> (type) { where tour_type: type }
  scope :vehicle_type, -> (vehicle_type) { where vehicle_type: vehicle_type }

  def static_path_map(point_limit: 200, precision: 4)
    return EmptyMap.new unless self.simplified_tour_points.count > 0

    map = GoogleStaticMap.new(width: 300, height: 300, api_key:ENV["ANDROID_GCM_API_KEY"])
    tourpoints = MapPolygon.new(:color => '0x0000ff', weight: 5, polyline: true)
    simplified_tour_points.ordered.each do |tp|
      tourpoints.points << MapLocation.new(latitude: tp.latitude.round(precision), longitude: tp.longitude.round(precision))
    end
    if tourpoints.points.length > 1
      map.paths << tourpoints
    end
    first_point = self.simplified_tour_points.ordered.first
    last_point = self.simplified_tour_points.ordered.last
    map.markers << MapMarker.new(label: 'D', color:'green', location: MapLocation.new(latitude: first_point.latitude.round(precision), longitude: first_point.longitude.round(precision)))
    map.markers << MapMarker.new(label: 'A', color:'red', location: MapLocation.new(latitude: last_point.latitude.round(precision), longitude: last_point.longitude.round(precision)))
    return map
  end
  
  def static_encounters_map(encounter_limit: 40, precision: 4)
    return EmptyMap.new unless self.encounters.count > 0

    map = GoogleStaticMap.new(width: 300, height: 300, api_key:ENV["ANDROID_GCM_API_KEY"])

    self.encounters.first(encounter_limit).each_with_index do |e,index|
      label = ApplicationController.helpers.marker_index(index)
      map.markers << MapMarker.new(label: label, color:'blue', location: MapLocation.new(latitude: e.latitude.round(precision), longitude: e.longitude.round(precision)))
    end

    return map
  end

  def force_close
    update(status: :closed, closed_at: DateTime.now)
  end

  def to_s
    "#{id} - by user #{user} at #{created_at}"
  end

  def empty_points?
    tour_points.count == 0
  end

  def community
    Community.new('entourage')
  end

  def group_type
    'tour'
  end

  def group_type_config
    @group_type_config ||= {
      'message_types' => ['text'],
      'roles' => ['creator', 'member']
    }
  end
end

class EmptyMap
  def url
    ''
  end
end

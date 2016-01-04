class TourSerializer < ActiveModel::Serializer
  attributes :id,
             :tour_type,
             :status,
             :vehicle_type,
             :distance,
             :organization_name,
             :organization_description,
             :start_time,
             :end_time,
             :user_id
  has_many :tour_points

  def distance
    object.length
  end

  def start_time
    object.tour_points.first.try(:passing_time)
  end

  def end_time
    object.tour_points.last.try(:passing_time)
  end

  def organization_name
    object.organization_name
  end

  def organization_description
    object.organization_description
  end
end
class AssociationEvent < ApplicationRecord
  belongs_to :association_event_source
  belongs_to :poi, optional: true

  scope :upcoming, -> { where('starts_at >= ?', Time.zone.now).order(:starts_at) }
  scope :poi_mapped, -> { where.not(poi_id: nil) }

  def match_poi!
    AssociationEventPoiMatcher.new(self).match!
  end
end

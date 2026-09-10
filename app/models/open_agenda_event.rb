class OpenAgendaEvent < ApplicationRecord
  belongs_to :open_agenda_source
  belongs_to :poi, optional: true

  scope :upcoming, -> { where('starts_at >= ?', Time.zone.now).order(:starts_at) }
  scope :poi_mapped, -> { where.not(poi_id: nil) }

  def match_poi!
    OpenAgendaEventPoiMatcher.new(self).match!
  end
end

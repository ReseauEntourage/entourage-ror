class OpenAgendaSource < ApplicationRecord
  belongs_to :partner, optional: true
  belongs_to :poi, optional: true
  has_many :open_agenda_events, -> { order(:starts_at) }, dependent: :destroy

  STATUSES = %w[not_checked exploitable not_exploitable].freeze

  validates :name, presence: true
  validates :agenda_uid, uniqueness: true, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  after_update :cascade_poi_to_events, if: :saved_change_to_poi_id?

  scope :ordered, -> { order(:name) }
  scope :unmapped, -> { where(partner_id: nil) }
  scope :mapped, -> { where.not(partner_id: nil) }
  scope :with_uid, -> { where.not(agenda_uid: nil) }
  scope :without_uid, -> { where(agenda_uid: nil) }
  scope :poi_mapped, -> { where.not(poi_id: nil) }
  scope :poi_unmapped, -> { where(poi_id: nil) }

  def mapped?
    partner_id.present?
  end

  def poi_mapped?
    poi_id.present?
  end

  def agenda_uid?
    agenda_uid.present?
  end

  def upcoming_events
    open_agenda_events.where('starts_at >= ?', Time.zone.now).order(:starts_at)
  end

  def sync!
    OpenAgendaSyncService.new(self).sync!
  end

  private

  def cascade_poi_to_events
    open_agenda_events.update_all(poi_id: poi_id)
  end
end

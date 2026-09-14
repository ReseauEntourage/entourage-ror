class AssociationEventSource < ApplicationRecord
  belongs_to :partner, optional: true
  belongs_to :poi, optional: true
  has_many :association_events, -> { order(:starts_at) }, dependent: :destroy

  PROVIDERS = %w[open_agenda hello_asso].freeze
  STATUSES = %w[not_checked exploitable not_exploitable].freeze

  SYNC_SERVICES = {
    'open_agenda' => 'OpenAgendaSyncService',
    'hello_asso'  => 'HelloAssoSyncService'
  }.freeze

  validates :name, presence: true
  validates :provider, inclusion: { in: PROVIDERS }
  validates :agenda_uid, uniqueness: true, allow_nil: true
  validates :helloasso_organization_slug, uniqueness: true, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  after_update :cascade_poi_to_events, if: :saved_change_to_poi_id?

  scope :ordered, -> { order(:name) }
  scope :unmapped, -> { where(partner_id: nil) }
  scope :mapped, -> { where.not(partner_id: nil) }
  scope :syncable, -> { where('agenda_uid IS NOT NULL OR helloasso_organization_slug IS NOT NULL') }
  scope :poi_mapped, -> { where.not(poi_id: nil) }
  scope :poi_unmapped, -> { where(poi_id: nil) }

  def mapped?
    partner_id.present?
  end

  def poi_mapped?
    poi_id.present?
  end

  def external_uid?
    agenda_uid.present? || helloasso_organization_slug.present?
  end

  def upcoming_events
    association_events.where('starts_at >= ?', Time.zone.now).order(:starts_at)
  end

  def sync!
    SYNC_SERVICES.fetch(provider).constantize.new(self).sync!
  end

  private

  def cascade_poi_to_events
    association_events.update_all(poi_id: poi_id)
  end
end

# A "Votre prochain pas" suggestion chosen for a user (the hero). Only heroes
# are stored: the "others" are computed on every call and never persisted.
#
# @see NextSteps::Current for the lifecycle (choice, validity, replacement)
class NextStep < ApplicationRecord
  KINDS = %w[outing neighborhood action content_path smalltalk poi post_message become_ambassador].freeze
  MODES = %w[segment need].freeze
  STATUSES = %w[active realised ignored expired closed].freeze
  SEGMENT_SOURCES = %w[computed assumed_new assumed_returning team].freeze

  # model of each kind's target; content_path keeps its 3 resources in target_ids
  TARGET_TYPES = {
    'outing' => 'Outing',
    'neighborhood' => 'Neighborhood',
    'action' => 'Action',
    'poi' => 'Poi',
    'post_message' => 'Neighborhood'
  }.freeze

  belongs_to :user
  has_many :interactions, class_name: :NextStepInteraction

  validates :kind, inclusion: { in: KINDS }
  validates :mode, inclusion: { in: MODES }
  validates :status, inclusion: { in: STATUSES }
  validates :segment_source, inclusion: { in: SEGMENT_SOURCES }
  validates_presence_of :first_displayed_at, :expires_at

  scope :active, -> { where(status: 'active') }

  def active?
    status == 'active'
  end

  # The target record, or nil when the suggestion has none or the target is gone.
  def target
    return unless target_type.present? && target_id.present?
    return @target if defined?(@target)

    @target = target_type.constantize.find_by(id: target_id)
  end

  def resources
    return Resource.none unless kind == 'content_path'

    Resource.where(id: target_ids)
  end

  def realise! at: Time.zone.now
    update!(status: 'realised', realised_at: at)
  end

  def ignore! at: Time.zone.now
    update!(status: 'ignored', ignored_at: at)
  end

  def expire! at: Time.zone.now
    update!(status: 'expired', closed_at: at)
  end

  def close! at: Time.zone.now
    update!(status: 'closed', closed_at: at)
  end
end

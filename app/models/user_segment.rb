class UserSegment < ApplicationRecord
  belongs_to :user

  # The segments of EngagementSegmentComputation, as the back-office filters
  # and colours them: key => [segment, sub-segment] (nil sub-segment: any)
  FILTERS = {
    'silencieux' => ['Silencieux', nil],
    'a_activer' => ['Silencieux', 'À activer'],
    'dormant' => ['Silencieux', 'Dormant'],
    'curieux' => ['Curieux', nil],
    'observateur' => ['Observateur', nil],
    'contributeur' => ['Contributeur', nil],
    'pilier' => ['Pilier', nil]
  }.freeze

  scope :matching, -> (key) {
    segment, sub_segment = FILTERS.fetch(key)

    sub_segment ? where(engagement_segment: segment, engagement_sub_segment: sub_segment) : where(engagement_segment: segment)
  }

  # "Silencieux / Dormant", "Curieux"…; nil when unclassified
  def label
    [engagement_segment, engagement_sub_segment].compact.join(' / ').presence
  end

  # The most precise key of FILTERS for this segment: "dormant" rather than "silencieux"
  def filter_key
    FILTERS.key([engagement_segment, engagement_sub_segment]) || FILTERS.key([engagement_segment, nil])
  end
end

# Append-only log of what the apps report about a suggestion, for the hero as
# for the "others".
class NextStepInteraction < ApplicationRecord
  PLACEMENTS = %w[hero others].freeze
  KINDS = %w[displayed why_opened tapped].freeze

  belongs_to :user
  belongs_to :next_step, optional: true

  validates :placement, inclusion: { in: PLACEMENTS }
  validates :kind, inclusion: { in: KINDS }
  validates :item_kind, inclusion: { in: NextStep::KINDS }, allow_nil: true
  validates_presence_of :next_step_id, if: -> { placement == 'hero' }
  validates_presence_of :item_kind, if: -> { placement == 'others' }
end

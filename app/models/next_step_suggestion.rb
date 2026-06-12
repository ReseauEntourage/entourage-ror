class NextStepSuggestion < ApplicationRecord
  SUGGESTION_TYPES = %w[first_step event connection group reengagement fallback].freeze
  TARGET_PROFILES = %w[offer_help ask_for_help all].freeze

  validates :suggestion_type, inclusion: { in: SUGGESTION_TYPES }
  validates :target_profile, inclusion: { in: TARGET_PROFILES }
  validates :title_template, :cta_label, presence: true

  scope :active, -> { where(active: true) }
  scope :for_profile, ->(goal) { where(target_profile: ['all', goal]) }
  scope :for_level, ->(level) {
    where('min_engagement_level <= ? AND max_engagement_level >= ?', level, level)
  }

  has_many :user_next_steps

  def title_for(user)
    interpolate(title_template, user)
  end

  def reason_for(user)
    return nil if reason_template.blank?
    interpolate(reason_template, user)
  end

  private

  def interpolate(template, user)
    template
      .gsub('{first_name}', user.first_name.to_s)
      .gsub('{zone}', user.address&.postal_code.to_s)
  end
end

class UserSmalltalk < ApplicationRecord
  include Deeplinkable

  CRITERIA = [:match_format, :match_locality, :match_gender, :match_interest]

  enum match_format: { one: 0, many: 1 }
  enum user_gender: { male: 0, female: 1, not_binary: 2 }
  enum user_profile: { offer_help: 0, ask_for_help: 1 }

  belongs_to :user
  belongs_to :smalltalk, optional: true

  # enum scope: match_format
  scope :one_format, -> { where(match_format: :one) }
  scope :many_format, -> { where(match_format: :many) }

  # enum scope: user_gender
  scope :male_gender, -> { where(user_gender: :male) }
  scope :female_gender, -> { where(user_gender: :female) }
  scope :not_binary_gender, -> { where(user_gender: :not_binary) }

  # enum scope: user_profile
  scope :offer_help_profile, -> { where(user_profile: :offer_help) }
  scope :ask_for_help_profile, -> { where(user_profile: :ask_for_help) }

  # filters
  scope :not_matched, -> { where(matched_at: nil) }

  def user= user
    self.user_latitude = user.latitude
    self.user_longitude = user.longitude
    self.user_gender = user.gender
    self.user_profile = user.is_offer_help? ? :offer_help : :ask_for_help

    super(user)
  end

  def find_and_save_match!
    return unless find_match.present?

    save_match(find_match)
  end

  def save_match user_smalltalk
    return if user.user_smalltalks.where.not(smalltalk_id: nil).distinct.count >= 3

    Smalltalk.transaction do
      target_smalltalk = user_smalltalk.smalltalk || create_smalltalk!

      associate_user_smalltalk(self, target_smalltalk)
      associate_user_smalltalk(user_smalltalk, target_smalltalk)

      ensure_join_request(self.user, target_smalltalk)
      ensure_join_request(user_smalltalk.user, target_smalltalk)

      target_smalltalk
    end
  end

  def find_match
    @find_match ||= find_matches.first
  end

  def find_matches
    @find_matches ||= UserSmalltalk
      .not_matched
      .where.not(user_id: user_id)
  end

  def find_matches_count_by criteria
    raise ArgumentError unless self.class.has_criteria?(criteria)

    find_matches.group(criteria).count
  end

  def find_almost_matches
    @find_almost_matches ||= find_matches
  end

  class << self
    def has_criteria? criteria
      criteria.present? && CRITERIA.include?(criteria.to_sym)
    end
  end

  private

  def create_smalltalk!
    Smalltalk.create!
  end

  def associate_user_smalltalk user_smalltalk, smalltalk
    user_smalltalk.update!(smalltalk: smalltalk)
  end

  def ensure_join_request user, smalltalk
    JoinRequest.find_or_create_by!(user: user, joinable: smalltalk, role: :member, status: :accepted)
  end
end

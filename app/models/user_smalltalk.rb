class UserSmalltalk < ApplicationRecord
  include Deeplinkable

  enum match_format: { one: 0, many: 1 }
  enum user_gender: { male: 0, female: 1 }
  enum user_profile: { offer_help: 0, ask_for_help: 1 }

  belongs_to :user
  belongs_to :smalltalk, optional: true

  # enum scope: match_format
  scope :one_format, -> { where(match_format: :one) }
  scope :many_format, -> { where(match_format: :many) }

  # enum scope: user_gender
  scope :male_gender, -> { where(user_gender: :male) }
  scope :female_gender, -> { where(user_gender: :female) }

  # enum scope: user_profile
  scope :offer_help_profile, -> { where(user_profile: :offer_help) }
  scope :ask_for_help_profile, -> { where(user_profile: :ask_for_help) }

  def find_matches
    Hash.new
  end

  def has_match?
    find_matches.any?
  end

  def match! conversation_id
  end

  def user= user
    self.user_latitude = user.latitude
    self.user_longitude = user.longitude
    self.user_gender = user.male? ? :male : :female
    self.user_profile = user.is_offer_help? ? :offer_help : :ask_for_help

    super(user)
  end
end

class UserSmalltalk < ApplicationRecord
  include Deeplinkable

  CRITERIA = [:match_format, :match_locality, :match_gender, :match_interest]

  enum match_format: { one: 0, many: 1 }
  enum user_gender: { male: 0, female: 1, not_binary: 2 }
  enum user_profile: { offer_help: 0, ask_for_help: 1 }

  belongs_to :user
  belongs_to :smalltalk, optional: true

  default_scope { where(deleted_at: nil) }

  scope :not_matched, -> { where(matched_at: nil) }
  scope :with_match_filter, -> (matched) {
    return where.not(matched_at: nil) if matched

    not_matched
  }

  scope :with_accessible_smalltalks_for_user, -> (user) {
    where(user: user)
      .where(member_status: JoinRequest::ACCEPTED_STATUS)
      .where.not(smalltalk_id: nil)
  }

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
    @find_match ||= match_in_existing_group || match_to_form_duo
  end

  # find_match
  def match_in_existing_group
    find_matches
      .where.not(smalltalk_id: nil)
      .joins(:smalltalk)
      .where("smalltalks.number_of_people < 5")
      .first
  end

  # find_match
  def match_to_form_duo
    find_matches.where(smalltalk_id: nil).first
  end

  def find_matches
    base_scope = UserSmalltalk.not_matched.where.not(user_id: user_id)

    base_scope = base_scope.where(match_format: match_format)
    base_scope = filter_by_locality(base_scope) if match_locality
    base_scope = filter_by_gender(base_scope) if match_gender
    base_scope = filter_by_common_interests(base_scope) if match_interest

    base_scope
  end

  def find_matches_count_by criteria
    raise ArgumentError unless self.class.has_criteria?(criteria)

    find_matches.group(criteria).count
  end

  def find_almost_matches
    scope = UserSmalltalk.not_matched
      .where.not(user_id: user_id)
      .where(match_format: match_format)

    scope = filter_by_locality(scope) if match_locality
    scope = filter_by_gender(scope) if match_gender

    scope
  end

  def filter_by_locality scope
    return scope unless user_latitude && user_longitude

    scope.where(
      <<~SQL.squish,
        ST_DWithin(
          ST_SetSRID(ST_MakePoint(user_smalltalks.user_longitude, user_smalltalks.user_latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
          ?
        )
      SQL
      user_longitude, user_latitude, 20_000
    )
  end

  def filter_by_gender scope
    scope.where(user_gender: user_gender)
  end

  def filter_by_common_interests scope
    scope.joins(user: :interests)
      .where(interests: { id: user.interest_ids })
      .distinct
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
    user_smalltalk.update!(smalltalk: smalltalk, matched_at: Time.current)
  end

  def ensure_join_request user, smalltalk
    JoinRequest.find_or_create_by!(
      user: user,
      joinable: smalltalk,
      role: :member,
      status: :accepted
    )
  end
end

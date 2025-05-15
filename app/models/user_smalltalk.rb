class UserSmalltalk < ApplicationRecord
  include Deeplinkable
  include UserSmalltalkable

  VIRTUAL_ATTRIBUTES = [:has_matched_format, :has_matched_gender, :has_matched_locality, :has_matched_interest, :unmatch_count]

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

  VIRTUAL_ATTRIBUTES.each do |virtual_attribute|
    define_method(virtual_attribute) do
      self[virtual_attribute]
    end
  end

  def user= user
    self.user_latitude = user.latitude
    self.user_longitude = user.longitude
    self.user_gender = user.gender
    self.user_profile = user.is_offer_help? ? :offer_help : :ask_for_help
    self.user_interest_ids = user.interest_ids

    super(user)
  end

  def find_and_save_match!
    return unless (user_smalltalk = find_match)
    return if joined_smalltalks.count >= 3

    Smalltalk.transaction do
      target_smalltalk = user_smalltalk.smalltalk || create_smalltalk_with!(user_smalltalk)

      associate_user_smalltalk(self, target_smalltalk)
      associate_user_smalltalk(user_smalltalk, target_smalltalk)

      ensure_join_request(self.user, target_smalltalk)
      ensure_join_request(user_smalltalk.user, target_smalltalk)

      target_smalltalk
    end
  end

  def force_and_save_match! smalltalk_id
    return unless smalltalk_id
    return unless target_smalltalk = Smalltalk.find_by(id: smalltalk_id)
    return if joined_smalltalks.count >= 3

    Smalltalk.transaction do
      associate_user_smalltalk(self, target_smalltalk)

      ensure_join_request(self.user, target_smalltalk)

      target_smalltalk
    end
  end

  def find_match
    @find_match ||= find_matches.first
  end

  def find_matches
    UserSmalltalk.exact_matches(self)
  end

  def find_matches_count_by criteria
    raise ArgumentError unless self.class.has_criteria?(criteria)

    find_matches.group(criteria).count
  end

  def find_almost_matches
    UserSmalltalk.best_matches(self)
  end

  class << self
    def has_criteria? criteria
      criteria.present? && CRITERIA.include?(criteria.to_sym)
    end
  end

  private

  def create_smalltalk_with! user_smalltalk
    Smalltalk.create!(match_format: user_smalltalk.match_format)
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

  def joined_smalltalks
    JoinRequest.where(user: user, joinable_type: :Smalltalk, status: JoinRequest::ACCEPTED_STATUS)
  end
end

class UserSmalltalk < ApplicationRecord
  include Deeplinkable
  include UserSmalltalkable

  VIRTUAL_ATTRIBUTES = [:has_matched_format, :has_matched_gender, :has_matched_locality, :has_matched_interest, :has_matched_profile, :unmatch_count]

  CRITERIA = [:match_format, :match_locality, :match_gender]

  enum match_format: { one: 0, many: 1 }
  enum user_gender: { male: 0, female: 1, not_binary: 2 }
  enum user_profile: { offer_help: 0, ask_for_help: 1 }

  belongs_to :user
  belongs_to :smalltalk, optional: true
  has_one :join_request, -> (user_smalltalk) {
    where(user_id: user_smalltalk.user_id, joinable_type: 'Smalltalk', status: 'accepted')
  }, primary_key: :smalltalk_id, foreign_key: :joinable_id

  default_scope {
    where(deleted_at: nil)
    .where("member_status is null or member_status != 'cancelled'")
  }

  validate :quota_must_not_be_reached, on: :create

  scope :not_matched, -> { where(matched_at: nil) }
  scope :with_match_filter, -> (matched) {
    return where.not(matched_at: nil) if matched

    not_matched
  }

  scope :with_accessible_smalltalks_for_user, -> (user) {
    joins(:smalltalk)
      .merge(Smalltalk.with_people)
      .where(user: user)
      .where(member_status: JoinRequest::ACCEPTED_STATUS)
  }

  VIRTUAL_ATTRIBUTES.each do |virtual_attribute|
    define_method(virtual_attribute) do
      self[virtual_attribute]
    end
  end

  def user=(user)
    assign_user_attributes(user)

    super(user)
  end

  def user_id=(user_id)
    user = User.find(user_id)
    assign_user_attributes(user)

    super(user_id)
  end

  def deleted?
    deleted_at.present?
  end

  def quota_reached?
    joined_smalltalks.count >= 3
  end

  def quota_must_not_be_reached
    if quota_reached?
      errors.add(:base, 'Quota has been reached. You can only join up to 3 smalltalks at a time.')
    end
  end

  def find_and_save_match!
    return unless find_match
    return if quota_reached?

    match_with_user_smalltalk!(find_match.id)
  end

  def force_and_save_match! smalltalk_id:, user_smalltalk_id:
    return match_with_smalltalk!(smalltalk_id) if smalltalk_id.present?

    match_with_user_smalltalk!(user_smalltalk_id) if user_smalltalk_id.present?
  end

  def match_with_user_smalltalk! user_smalltalk_id
    return unless user_smalltalk = UserSmalltalk.find(user_smalltalk_id)

    Smalltalk.transaction do
      target_smalltalk = user_smalltalk.smalltalk || create_smalltalk_with!(user_smalltalk)

      associate_user_smalltalk(self, target_smalltalk)
      associate_user_smalltalk(user_smalltalk, target_smalltalk)

      ensure_join_request(self.user, target_smalltalk)
      ensure_join_request(user_smalltalk.user, target_smalltalk)

      target_smalltalk
    end
  end

  def match_with_smalltalk! smalltalk_id
    return unless smalltalk_id
    return unless target_smalltalk = Smalltalk.find_by(id: smalltalk_id)
    return if quota_reached?

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
    build_matches(UserSmalltalk.exact_matches(self).limit(10))
  end

  def find_almost_matches
    update_column(:last_almost_match_computation_at, Time.zone.now)

    build_matches(UserSmalltalk.best_matches(self).limit(10))
  end

  def find_matches_count_by criteria
    raise ArgumentError unless self.class.has_criteria?(criteria)

    find_matches.group(criteria).count
  end

  # Interestable
  def interests
    Tag.where(id: user_interest_ids)
  end

  def interest_names
    interests.map(&:name).sort
  end

  def interest_i18n
    interest_names.map { |interest| I18n.t("tags.interests.#{interest}") }
  end

  class << self
    def has_criteria? criteria
      criteria.present? && CRITERIA.include?(criteria.to_sym)
    end
  end

  private

  def assign_user_attributes(user)
    self.user_latitude = user.latitude
    self.user_longitude = user.longitude
    self.user_gender = user.gender
    self.user_profile = user.is_ask_for_help? ? :ask_for_help : :offer_help
    self.user_interest_ids = user.interest_ids
  end

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

  def build_matches matches, max_unmatch_count = 1
    user_ids = matches.flat_map(&:user_ids) + matches.map(&:user_id)
    users_by_id = User.where(id: user_ids.uniq).index_by(&:id)

    matches.reject do |record|
      record.unmatch_count > max_unmatch_count
    end.map do |record|
      UserSmalltalkMatch.new(
        id: record.id,
        smalltalk_id: record.smalltalk_id,
        user: users_by_id[record.user_id],
        users: record.user_ids.map { |user_id| users_by_id[user_id] },
        has_matched_format: record.has_matched_format,
        has_matched_gender: record.has_matched_gender,
        has_matched_locality: record.has_matched_locality,
        has_matched_interest: record.has_matched_interest,
        has_matched_profile: record.has_matched_profile,
        unmatch_count: record.unmatch_count
      )
    end
  end
end

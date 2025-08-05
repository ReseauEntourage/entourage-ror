class JoinRequest < ApplicationRecord
  ACCEPTED_STATUS="accepted"
  PENDING_STATUS="pending"
  REJECTED_STATUS="rejected"
  CANCELLED_STATUS="cancelled"

  STATUS = [ACCEPTED_STATUS, PENDING_STATUS, REJECTED_STATUS, CANCELLED_STATUS]

  include JoinRequestAcceptTracking
  include Salesforcable

  belongs_to :user
  belongs_to :validated_user, -> {
    where(validation_status: 'validated', deleted: false)
  }, class_name: 'User', foreign_key: 'user_id', optional: true
  belongs_to :joinable, polymorphic: true
  belongs_to :entourage, -> {
    where("join_requests.joinable_type = 'Entourage'")
  }, foreign_key: :joinable_id, optional: true # why optional? Cause it might belongs_to Neighborhood

  has_many :siblings, -> (join_request) {
    where(joinable_type: join_request.joinable_type, joinable_id: join_request.joinable_id)
      .where.not(id: join_request.id)
    },
    class_name: 'JoinRequest',
    foreign_key: :joinable_id,
    primary_key: :joinable_id

  attr_accessor :last_chat_message, :siblings

  validates :user_id, :joinable_id, :joinable_type, :status, presence: true
  validates_uniqueness_of :joinable_id, {scope: [:joinable_type, :user_id], message: "a déjà été ajouté"}
  validates_inclusion_of :status, in: ["pending", "accepted", "rejected", "cancelled"]
  validates :status, inclusion: { in: ['accepted'] }, if: Proc.new { |join_request|
    # can not remove creator
    join_request.joinable.present? &&
      join_request.joinable.respond_to?(:user_id) &&
      join_request.joinable.user_id == join_request.user_id
  }
  validates :role, presence: true, inclusion: { in: ['member', 'creator'] }, if: :neighborhood?
  validates :role, presence: true,
                   inclusion: { in: -> (r) { r.joinable&.group_type_config&.dig('roles') || [] }, allow_nil: true },
                   unless: :neighborhood?
  validates_inclusion_of :report_prompt_status, in: ['display', 'dismissed', 'reported'], allow_nil: true

  scope :accepted, -> {where(status: ACCEPTED_STATUS)}
  scope :pending,  -> {where(status: PENDING_STATUS)}
  scope :rejected, -> {where(status: REJECTED_STATUS)}
  scope :cancelled, -> {where(status: CANCELLED_STATUS)}

  scope :ordered_by_validated_users, -> {
    joins(:validated_user).order("join_requests.role, users.first_name")
  }

  scope :search_by_member, ->(search) {
    strip = search && search.strip.downcase

    return unless strip.present?

    where(user_id: User.search_by_first_name(strip))
  }

  scope :with_joinable_type, -> (joinable_type) {
    return unless joinable_type.present?
    return unless joinable_type.respond_to?(:to_s)

    return where(joinable_type: :Entourage).where(
      joinable_id: Entourage.where(group_type: joinable_type.to_s.downcase)
    ) if ['action', 'outing', 'conversation'].include?(joinable_type.to_s.downcase)

    where(joinable_type: joinable_type)
  }

  scope :without_joinable_type, -> (joinable_type) {
    return unless joinable_type.present?

    where.not(joinable_type: joinable_type)
  }

  after_save :joinable_callback
  after_destroy :joinable_callback
  before_save :reset_confirmed_at_unless_accepted

  def set_chat_messages_as_read
    update_column(:last_message_read, DateTime.now)
    update_column(:unread_messages_count, 0)
  end

  def set_chat_messages_as_unread
    update_column(:last_message_read, nil)
    update_column(:unread_messages_count, joinable.chat_messages
      .where(status: [:active, :updated])
      .where(ancestry: nil)
      .count
    )
  end

  def set_chat_messages_as_read_from datetime
    update_column(:last_message_read, datetime)
    update_column(:unread_messages_count, joinable.chat_messages
      .where("created_at > ?", datetime)
      .where(status: [:active, :updated])
      .where(ancestry: nil)
      .count
    )
  end

  def entourage?
    joinable_type == 'Entourage'
  end

  def outing?
    entourage? && joinable.outing?
  end

  def conversation?
    entourage? && joinable.conversation?
  end

  def neighborhood?
    joinable_type == 'Neighborhood'
  end

  def smalltalk?
    joinable_type == 'Smalltalk'
  end

  def entourage_id
    nil unless entourage?
    joinable_id
  end

  def self.with_entourage_invitations
    joins(%(
      left join entourage_invitations on (
        join_requests.joinable_type = 'Entourage' and
        entourage_invitations.invitable_id = join_requests.joinable_id and
        entourage_invitations.invitee_id = join_requests.user_id
      )
    ))
    .select(%(
      join_requests.*,
      entourage_invitations.id as entourage_invitation_id,
      entourage_invitations.status as entourage_invitation_status
    ))
  end

  def self.with_unread_messages
    where(status: :accepted).where("unread_messages_count > 0")
  end

  STATUS.each do |check_status|
    define_method("is_#{check_status}?") do
      status == check_status
    end
  end

  def pending?
    return unless status
    status.to_sym == :pending
  end

  def rejected?
    return unless status
    status.to_sym == :rejected
  end

  def accepted?
    return unless status
    status.to_sym == :accepted
  end

  def cancelled?
    return unless status
    status.to_sym == :cancelled
  end

  # these 3 methods manage the skip_conversation_uuid_update flag.
  # see join_callback and ChatMessageBuilder#create
  def initialize(*)
    @skip_conversation_uuid_update = false
    super
  end

  def skip_conversation_uuid_update!
    @skip_conversation_uuid_update = true
  end

  def _update_record(*)
    super.tap do
      @skip_conversation_uuid_update = false
    end
  end

  def simplified_status
    # Not sure it's needed anymore.
    # see commit 363a77c2df9b9e6e9a93f68796f4ac8f2c527868
    return "not_requested" if destroyed?

    # we don't return 'rejected' or 'cancelled' anymore as we don't want these states to
    # be treated differently by the clients. See EN-3073
    return "not_requested" if status.in?(['rejected', 'cancelled'])

    status
  end

  private

  def joinable_callback(*args)
    return if joinable.nil?

    # touch the group for new pending join requests
    if (saved_change_to_id? || saved_change_to_status?) && status == 'pending'
      FeedUpdatedAt.update(joinable_type, joinable_id, requested_at || created_at)
    end

    # update the conversation's uuid_v2 to match the list of participants
    if joinable.is_a?(Entourage) && joinable.conversation?
      # TODO: handle status? (saved_change_to_status?)
      if @skip_conversation_uuid_update != true && (saved_change_to_id? || destroyed?)
        joinable.update!(
          uuid_v2: ConversationService.hash_for_participants(joinable.join_requests.pluck(:user_id), validated: false)
        )
      end
    end
  end

  def reset_confirmed_at_unless_accepted
    return unless confirmed_at.present?

    self.confirmed_at = nil unless status == 'accepted'
  end
end

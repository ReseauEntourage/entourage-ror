class JoinRequest < ActiveRecord::Base
  ACCEPTED_STATUS="accepted"
  PENDING_STATUS="pending"
  REJECTED_STATUS="rejected"
  CANCELLED_STATUS="cancelled"

  STATUS = [ACCEPTED_STATUS, PENDING_STATUS, REJECTED_STATUS, CANCELLED_STATUS]

  include Experimental::AutoAccept::JoinRequestCallback
  include JoinRequestAcceptTracking

  belongs_to :user
  belongs_to :joinable, polymorphic: true
  belongs_to :tour,      -> { where("join_requests.joinable_type = 'Tour'")      }, foreign_key: :joinable_id
  belongs_to :entourage, -> { where("join_requests.joinable_type = 'Entourage'") }, foreign_key: :joinable_id

  validates :user_id, :joinable_id, :joinable_type, :status, presence: true
  validates_uniqueness_of :joinable_id, {scope: [:joinable_type, :user_id], message: "a déjà été ajouté"}
  validates_inclusion_of :status, in: ["pending", "accepted", "rejected", "cancelled"]
  validates :role, presence: true,
                   inclusion: { in: -> (r) { r.joinable&.group_type_config&.dig('roles') || [] }, allow_nil: true }
  validates_inclusion_of :report_prompt_status, in: ['display', 'dismissed', 'reported'], allow_nil: true

  scope :accepted, -> {where(status: ACCEPTED_STATUS)}
  scope :pending,  -> {where(status: PENDING_STATUS)}
  scope :rejected, -> {where(status: REJECTED_STATUS)}
  scope :cancelled, -> {where(status: CANCELLED_STATUS)}

  after_save :joinable_callback
  after_destroy :joinable_callback

  after_save :requested_at_callback

  def requested_at_callback
    return unless entourage?
    return unless requested_at
    return unless message.present?
    return unless new_record? || requested_at_changed? || status_changed?

    if ['pending', 'accepted'].include?(status)
      Entourage.find(joinable_id).update_attribute(:max_join_request_requested_at, requested_at)
    else
      # could be achieved in a job
      join_request = JoinRequest.select('joinable_id, max(requested_at) as max_requested_at')
        .where(joinable_type: 'Entourage', joinable_id: joinable_id, status: ['pending', 'accepted'])
        .group('joinable_id').order('joinable_id').first

      Entourage.find(joinable_id).update_attribute(:max_join_request_requested_at, join_request&.max_requested_at)
    end
  end

  def entourage?
    joinable_type == 'Entourage'
  end

  def self.with_entourage_invitations
    joins(%(
      left join entourage_invitations on (
        entourage_invitations.invitable_type = join_requests.joinable_type and
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
    where(status: :accepted)
    .joins(%(
      join chat_messages on (
        messageable_id = joinable_id and
        messageable_type = joinable_type and
        (last_message_read is null or
         chat_messages.created_at > last_message_read)
      )
    ))
  end

  STATUS.each do |check_status|
    define_method("is_#{check_status}?") do
      status == check_status
    end
  end

  def archived?
    archived_at && archived_at >= joinable.feed_updated_at
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
    if (id_changed? || status_changed?) && status == 'pending'
      FeedUpdatedAt.update(joinable_type, joinable_id, requested_at || created_at)
    end

    # update the conversation's uuid_v2 to match the list of participants
    if joinable.group_type == 'conversation'
      # TODO: handle status? (status_changed?)
      if @skip_conversation_uuid_update != true && (id_changed? || destroyed?)
        joinable.update!(
          uuid_v2: ConversationService.hash_for_participants(
            joinable.join_requests.pluck(:user_id), validated: false))
      end
    end
  end
end

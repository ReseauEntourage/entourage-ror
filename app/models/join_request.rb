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

  scope :accepted, -> {where(status: ACCEPTED_STATUS)}
  scope :pending,  -> {where(status: PENDING_STATUS)}
  scope :rejected, -> {where(status: REJECTED_STATUS)}
  scope :cancelled, -> {where(status: CANCELLED_STATUS)}

  after_save :joinable_callback
  after_destroy :joinable_callback

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
    joins(%(
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

  private

  def joinable_callback(*args)
    return if joinable.nil?

    # touch the group for new pending join requests
    if (id_changed? || status_changed?) && status == 'pending'
      FeedUpdatedAt.update(joinable_type, joinable_id, requested_at || created_at)
    end

    if joinable.group_type == 'conversation'
      # TODO: handle status?
      if id_changed? || destroyed? # || status_changed?
        joinable.update!(
          uuid_v2: ConversationService.hash_for_participants(
            joinable.join_requests.pluck(:user_id), validated: false))
      end
    end
  end
end

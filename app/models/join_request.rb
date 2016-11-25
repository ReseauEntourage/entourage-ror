class JoinRequest < ActiveRecord::Base
  ACCEPTED_STATUS="accepted"
  PENDING_STATUS="pending"
  REJECTED_STATUS="rejected"

  STATUS = [ACCEPTED_STATUS, PENDING_STATUS, REJECTED_STATUS]

  belongs_to :user
  belongs_to :joinable, polymorphic: true

  validates :user_id, :joinable_id, :joinable_type, :status, presence: true
  validates_uniqueness_of :joinable_id, {scope: [:user_id], message: "a déjà été ajouté"}
  validates_inclusion_of :status, in: ["pending", "accepted", "rejected"]

  scope :accepted, -> {where(status: ACCEPTED_STATUS)}
  scope :pending,  -> {where(status: PENDING_STATUS)}
  scope :rejected, -> {where(status: REJECTED_STATUS)}

  STATUS.each do |check_status|
    define_method("is_#{check_status}?") do
      status == check_status
    end
  end
end

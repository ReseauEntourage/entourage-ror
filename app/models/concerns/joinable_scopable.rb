module JoinableScopable
  extend ActiveSupport::Concern

  included do
    has_many :join_requests, as: :joinable, dependent: :destroy

    has_many :members, through: :join_requests, source: :user
    has_many :accepted_members, -> { where("join_requests.status = 'accepted'") }, through: :join_requests, source: :user

    scope :joined_by, -> (user) {
      joins(:join_requests).where(join_requests: {
        user: user, status: JoinRequest::ACCEPTED_STATUS
      })
    }
    scope :not_joined_by, -> (user) {
      where.not(id: joined_by(user))
    }
  end

  def members_has_changed!
    return unless has_attribute?(:number_of_people)

    update_column(:number_of_people, accepted_members.count)
  end

  def members_count
    return number_of_people if respond_to?(:number_of_people)

    members.length
  end

  def set_forced_join_request_as_member! user
    join_request = user.join_requests.find_by(joinable: self)

    return join_request if join_request.present? && join_request.accepted?

    if join_request.present?
      join_request.status = :accepted
    else
      join_request = JoinRequest.new(joinable: self, user: user, role: :member, status: :accepted)
    end

    join_request.save!
    join_request
  end
end

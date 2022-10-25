module JoinableScopable
  extend ActiveSupport::Concern

  included do
    scope :joined_by, -> (user) {
      joins(:join_requests).where(join_requests: {
        user: user, status: JoinRequest::ACCEPTED_STATUS
      })
    }
    scope :not_joined_by, -> (user) {
      where.not(id: joined_by(user))
    }
  end
end

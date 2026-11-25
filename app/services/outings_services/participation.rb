module OutingsServices
  # Joining and leaving an outing, shared by the app (Api::V1::Outings::UsersController) and by
  # the AI assistant (Api::V1::Assistant::...), so that both apply the same rules and have the
  # same effects (observers, notifications, counters).
  #
  # The right to act is the one of the user: the service never skips a validation of JoinRequest.
  class Participation
    attr_reader :outing, :user

    def initialize outing:, user:
      @outing = outing
      @user = user
    end

    # The accepted membership of the user (a new one, or the existing one set back to accepted),
    # not saved. The role can only be `organizer` for an ambassador who asks for it.
    def build_membership distance: nil, role: nil
      membership = JoinRequest.where(joinable: outing, user: user).first
      membership ||= JoinRequest.new(joinable: outing, user: user, distance: distance, role: :participant, status: :accepted)
      membership.status = :accepted
      membership.role = if user.ambassador? && role == 'organizer'
        :organizer
      else
        :participant
      end

      membership
    end

    # Joins the outing. Returns the membership, saved when `membership.errors` is empty.
    # Joining again an outing already joined changes nothing and notifies nobody.
    def join distance: nil, role: nil
      membership = build_membership(distance: distance, role: role)
      membership.save
      membership
    end

    # Leaves the outing. Returns the membership (cancelled when `membership.errors` is empty),
    # or nil when the user never joined this outing.
    def leave
      membership = JoinRequest.where(joinable: outing, user: user).first
      return unless membership

      membership.update(status: :cancelled)
      membership
    end
  end
end

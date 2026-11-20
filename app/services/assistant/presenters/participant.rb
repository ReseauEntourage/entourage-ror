module Assistant
  module Presenters
    # A person that the app shows to a member among the participants of an outing.
    class Participant
      def initialize join_request
        @join_request = join_request
      end

      def as_json(*)
        user = @join_request.user

        Support.member(user).merge(
          groupRole: @join_request.role,
          communityRoles: UserPresenter.new(user: user).public_targeting_profiles
        )
      end
    end
  end
end

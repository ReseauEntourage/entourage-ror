module Assistant
  module Presenters
    # A person that the app shows to a member among the participants of an outing: their role in
    # the outing and their public roles in the community, as one list.
    class Participant
      def initialize join_request
        @join_request = join_request
      end

      def as_json(*)
        user = @join_request.user

        {
          id: user.uuid,
          displayName: Support.display_name(user),
          roles: [@join_request.role, *UserPresenter.new(user: user).public_targeting_profiles].compact
        }
      end
    end
  end
end

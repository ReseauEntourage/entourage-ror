module Assistant
  module Actions
    # Joins a group (neighborhood) in the name of the user, as Api::V1::Neighborhoods::UsersController
    # does: in the app joining a group is immediate (an accepted JoinRequest, role member), there
    # is no approval step. Joining again changes nothing.
    class JoinGroup < Base
      def initialize user:, group_id:
        super(user: user)
        @group_id = group_id
      end

      def call
        require_param!(@group_id, 'group id')
        group = ::Neighborhood.find_by_id_or_uuid(@group_id.to_s) || refuse!(404, 'NOT_FOUND', 'Group not found.')

        membership = ::JoinRequest.find_by(joinable: group, user: user)
        if membership&.accepted?
          return outcome(201, { groupId: group.uuid_v2, status: 'joined' }, membership)
        end

        membership ||= ::JoinRequest.new(joinable: group, user: user, role: :member)
        membership.status = :accepted
        refuse_with_errors!(membership, 'CANNOT_JOIN', 'Could not join the group.') unless membership.save

        outcome(201, { groupId: group.uuid_v2, status: 'joined' }, membership)
      end
    end
  end
end

module Assistant
  module Actions
    # Cancels the registration of the user to an outing, as the app does.
    class LeaveOuting < Base
      def initialize user:, outing_id:
        super(user: user)
        @outing_id = outing_id
      end

      def call
        outing = find_outing!(@outing_id)
        membership = ::OutingsServices::Participation.new(outing: outing, user: user).leave
        refuse!(404, 'NOT_REGISTERED', 'The user is not registered to this outing.') unless membership
        refuse_with_errors!(membership, 'CANNOT_LEAVE', 'Could not cancel the registration.') unless membership.errors.empty?

        outcome(200, { outingId: outing.uuid_v2, status: 'unregistered' }, membership)
      end
    end
  end
end

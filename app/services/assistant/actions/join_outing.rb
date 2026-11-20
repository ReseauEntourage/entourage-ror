module Assistant
  module Actions
    # Registers the user to an outing, as the app does (OutingsServices::Participation): same
    # validations, same effects (members, notification to the organizer, counters). Registering
    # again changes nothing and notifies nobody.
    #
    # Neither the place limit nor `reserved_female` refuse a registration in the app today (see
    # design.md, spike 1.1): the same refusals as the app means none of them here either.
    class JoinOuting < Base
      def initialize user:, outing_id:
        super(user: user)
        @outing_id = outing_id
      end

      def call
        outing = find_outing!(@outing_id)
        membership = ::OutingsServices::Participation.new(outing: outing, user: user).join
        refuse_with_errors!(membership, 'CANNOT_JOIN', 'Could not register to the outing.') unless membership.errors.empty?

        outcome(201, { outingId: outing.uuid_v2, status: 'registered' }, membership)
      end
    end
  end
end

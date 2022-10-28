module V1
  module Entourages
    module Blockers
      def blockers
        return {} unless respond_to?(:scope) && scope[:user]
        return {} unless respond_to?(:other_participant) && other_participant

        UserBlockedUser
          .with_users([scope[:user].id, other_participant.id])
          .map(&:user_id)
          .compact
          .uniq
          .map do |blocker|
            blocker == scope[:user].id ? :me : :participant
          end
      end
    end
  end
end

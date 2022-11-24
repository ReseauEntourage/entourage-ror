module V1
  module Entourages
    module Blockers
      def blockers
        return [] unless object.is_a?(Entourage)
        return [] unless object.conversation?
        return [] unless respond_to?(:scope) && scope[:user]
        return [] unless other_participant_id

        UserBlockedUser
          .with_users([scope[:user].id, other_participant_id])
          .map(&:user_id)
          .compact
          .uniq
          .map do |blocker|
            blocker == scope[:user].id ? :me : :participant
          end
      end

      private

      def other_participant_id
        @other_participant_id ||= object.member_ids.find do |member_id|
          member_id != scope[:user].id
        end
      end
    end
  end
end

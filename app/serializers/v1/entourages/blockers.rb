module V1
  module Entourages
    module Blockers
      def blockers
        return [] unless object.is_a?(Entourage)
        return [] unless object.conversation?
        return [] unless respond_to?(:scope) && scope[:user]
        return [] unless other_participant_id

        blocker_ids.map do |blocker|
          blocker == scope[:user].id ? :me : :participant
        end
      end

      private

      def blocker_ids
        user_ids = [scope[:user].id, other_participant_id]
        preloaded = object.preloaded_user_blocks&.fetch(scope[:user].id, nil)

        return UserBlockedUser.with_users(user_ids).map(&:user_id).compact.uniq unless preloaded

        preloaded.select { |user_id, blocked_user_id| [user_id, blocked_user_id].sort == user_ids.sort }.map(&:first).uniq
      end

      def other_participant_id
        @other_participant_id ||= begin
          return object.member_ids.find { |id| id != scope[:user].id } unless object.association(:accepted_members).loaded?

          # accepted_members can miss a real participant whose own join_request
          # isn't "accepted" (e.g. status "hidden") — fall back to member_ids.
          object.accepted_members.map(&:id).find { |id| id != scope[:user].id } ||
            (object.member_ids - [scope[:user].id]).first
        end
      end
    end
  end
end

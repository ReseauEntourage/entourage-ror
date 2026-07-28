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

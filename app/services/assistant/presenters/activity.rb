module Assistant
  module Presenters
    # What the user did in the app: outings (upcoming and past), groups, publications and help they
    # answered, discussions. Never the content of a message, private or not: a discussion is only
    # the fact that it exists. Every list is bounded to the latest items, and loaded in a fixed
    # number of queries (no N+1).
    class Activity
      LIMIT = 20

      def initialize user
        @user = user
      end

      def as_json(*)
        {
          upcomingOutings: outings(:upcoming),
          pastOutings: outings(:past),
          groups: groups,
          helpRequests: publications(Solicitation),
          helpOffers: publications(Contribution),
          answeredHelp: answered_help,
          conversations: conversations
        }
      end

      private

      attr_reader :user

      def outings kind
        scope = Outing.where(id: user.accepted_join_requests.where(joinable_type: 'Entourage').select(:joinable_id))
        scope = if kind == :upcoming
          scope.active.future_or_ongoing.default_order
        else
          scope.accepted.ending_before(Time.zone.now).reorder(Arel.sql("metadata->>'starts_at' desc"))
        end
        records = scope.limit(LIMIT).to_a
        join_requests = user.accepted_join_requests.where(joinable_type: 'Entourage', joinable_id: records.map(&:id)).index_by(&:joinable_id)

        records.map do |outing|
          join_request = join_requests[outing.id]
          {
            id: outing.uuid_v2,
            title: outing.title.presence,
            startsAt: Support.iso8601(outing.starts_at),
            endsAt: Support.iso8601(outing.ends_at),
            role: join_request&.role,
            participated: join_request&.participate_at.present?
          }
        end
      end

      def groups
        user.neighborhood_memberships.reorder('join_requests.created_at desc').limit(LIMIT).map do |neighborhood|
          { id: neighborhood.uuid_v2, name: neighborhood.name.presence }
        end
      end

      def publications klass
        klass.where(user_id: user.id).where(status: %w[open full closed]).limit(LIMIT).map do |action|
          { id: action.uuid_v2, title: action.title.presence, status: action.status, createdAt: Support.iso8601(action.created_at) }
        end
      end

      # Publications of other members that the user answered (joined).
      def answered_help
        actions = Action.where(id: user.accepted_join_requests.where(joinable_type: 'Entourage').select(:joinable_id))
          .where.not(user_id: user.id).limit(LIMIT)

        actions.map do |action|
          { id: action.uuid_v2, type: action.contribution? ? 'offer' : 'request', title: action.title.presence }
        end
      end

      def conversations
        records = Conversation.where(id: user.accepted_join_requests.where(joinable_type: 'Entourage').select(:joinable_id))
          .includes(join_requests: :user).reorder(created_at: :desc).limit(LIMIT)

        records.map do |conversation|
          other = conversation.join_requests.map(&:user).find { |member| member.id != user.id }
          { id: conversation.uuid_v2, with: Support.member(other), startedAt: Support.iso8601(conversation.created_at) }
        end
      end
    end
  end
end

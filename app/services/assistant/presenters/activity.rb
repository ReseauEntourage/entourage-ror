module Assistant
  module Presenters
    # What the user did in the app: outings (upcoming and past), groups, publications, discussions.
    # Never the content of a message, private or not: a discussion is only counted. Every list is
    # bounded to the latest items, and loaded in a fixed number of queries (no N+1).
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
          helpPosts: help_posts,
          connectionsCount: connections_count
        }
      end

      private

      attr_reader :user

      def outings kind
        scope = ::Outing.where(id: user.accepted_join_requests.where(joinable_type: 'Entourage').select(:joinable_id))
        scope = if kind == :upcoming
          scope.active.future_or_ongoing.default_order
        else
          scope.accepted.ending_before(Time.zone.now).reorder(Arel.sql("metadata->>'starts_at' desc"))
        end
        records = scope.limit(LIMIT).to_a
        counts = EventBrief.counts(records)

        records.map { |outing| EventBrief.new(outing, participants_count: counts[outing.id] || 0).as_json }
      end

      def groups
        user.neighborhood_memberships.reorder('join_requests.created_at desc').limit(LIMIT).map do |neighborhood|
          { id: neighborhood.uuid_v2, name: neighborhood.name.presence }
        end
      end

      # The requests and offers that the user published, the latest first.
      def help_posts
        actions = ::Action.unscoped.where(group_type: :action, entourage_type: %w[ask_for_help contribution], user_id: user.id, status: %w[open full closed])
          .order(created_at: :desc, id: :desc).limit(LIMIT)

        actions.map do |action|
          { id: action.uuid_v2, kind: action.entourage_type == 'contribution' ? 'offer' : 'request', title: action.title.presence }
        end
      end

      # The one-to-one discussions that were started: the number, never what was said.
      def connections_count
        ::Conversation.where(id: user.accepted_join_requests.where(joinable_type: 'Entourage').select(:joinable_id))
          .where('number_of_root_chat_messages > 0').count
      end
    end
  end
end

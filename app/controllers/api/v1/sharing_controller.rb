module Api
  module V1
    class SharingController < Api::V1::BaseController
      def groups
        groups = find_groups(current_user_or_anonymous)
        render json: groups, status: 200, each_serializer: ::V1::EntourageSerializer, scope: {user: current_user_or_anonymous, sharing_selection: true}
      end

      private

      def find_groups user
        return Entourage.none if user.anonymous?

        groups = Entourage.where(status: :open)
        groups = groups.joins(:join_requests).where(
          join_requests: {
            user_id: user.id,
            status: :accepted
          }
        )
        groups = groups.order(updated_at: :desc) # TODO: feed_updated_at?
        groups = groups.limit(100)
      end
    end
  end
end

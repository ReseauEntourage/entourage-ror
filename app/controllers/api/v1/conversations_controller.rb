module Api
  module V1
    class ConversationsController < Api::V1::BaseController
      def index
        conversations = Entourage.joins(:join_requests)
          .includes(:members, :join_requests)
          .where(group_type: [:conversation, :action])
          .where('join_requests.user_id = ?', current_user.id)
          .order(updated_at: :desc)
          .page(page).per(per)

        render json: conversations, root: :conversations, each_serializer: ::V1::ConversationSerializer, scope: {
          user: current_user
        }
      end

      def show
      end

      private

      def page
        params[:page] || 1
      end

      def per
        params[:per] || 25
      end
    end
  end
end

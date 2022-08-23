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

      def private
        entourages = Entourage.joins(:join_requests)
          .includes(:members, :join_requests, { user: :partner })
          .where(group_type: :conversation)
          .where('join_requests.user_id = ?', current_user.id)
          .order(updated_at: :desc)
          .page(params[:page] || 1).per(per)

        render json: entourages, root: :entourages, each_serializer: ::V1::EntourageSerializer, scope: {
          user: current_user, include_last_message: true
        }
      end

      def group
        entourages = Entourage.joins(:join_requests)
          .includes(:join_requests, { user: :partner })
          .where(group_type: [:action, :outing])
          .where('join_requests.user_id = ?', current_user.id)
          .where('join_requests.status = ?', :accepted)
          .order(updated_at: :desc)
          .page(params[:page] || 1).per(per)

        render json: entourages, root: :entourages, each_serializer: ::V1::EntourageSerializer, scope: {
          user: current_user, include_last_message: true
        }
      end

      def metadata
        entourages = Entourage.joins(:join_requests)
          .select(:id, :group_type)
          .includes(:join_requests, { user: :partner })
          .where('join_requests.user_id = ?', current_user.id)
          .where('join_requests.status = ?', :accepted)

        unreads = UserServices::UnreadMessages.new(user: current_user).unread_by_group_type

        render json: {
          conversations: {
            count: entourages.filter{ |entourage| entourage.conversation? }.count,
            unread: unreads[:conversations]
          },
          actions: {
            count: entourages.filter{ |entourage| entourage.action? }.count,
            unread: unreads[:actions]
          },
          outings: {
            count: entourages.filter{ |entourage| entourage.outing? }.count,
            unread: unreads[:outings]
          }
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

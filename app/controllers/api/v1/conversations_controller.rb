module Api
  module V1
    class ConversationsController < Api::V1::BaseController
      before_action :set_conversation, only: [:show]
      before_action :ensure_is_member, only: [:show]

      after_action :set_last_message_read, only: [:show]

      def index
        conversations = Entourage.joins(:join_requests)
          .includes(:members, :join_requests, :chat_messages)
          .where.not(chat_messages: { id: nil })
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
        render json: @conversation, root: :conversation, serializer: ::V1::ConversationHomeSerializer
      end

      def create
        participant_ids = [conversation_params[:user_id], current_user.id]

        unless @conversation = Entourage.findable.find_by(uuid_v2: ConversationService.hash_for_participants(participant_ids))
          @conversation = ConversationService.build_conversation(participant_ids: participant_ids)
          @conversation.public = false
          @conversation.create_from_join_requests!
        end

        render json: @conversation, status: 201, root: :conversation, serializer: ::V1::ConversationHomeSerializer
      rescue => e
        render json: { message: 'unable to create conversation' }, status: :bad_request
      end

      private

      def page
        params[:page] || 1
      end

      def per
        params[:per] || 25
      end

      def set_conversation
        @conversation = Entourage.find(params[:id])
      end

      def conversation_params
        params.require(:conversation).permit(:user_id)
      end

      def ensure_is_member
        render json: { message: 'unauthorized user' } unless join_request
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @conversation, user: @current_user, status: :accepted).first
      end

      def set_last_message_read
        return unless join_request

        join_request.update(last_message_read: Time.now)
      end
    end
  end
end

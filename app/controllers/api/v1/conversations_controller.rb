module Api
  module V1
    class ConversationsController < Api::V1::BaseController
      before_action :set_conversation, only: [:show, :report, :destroy]
      before_action :ensure_is_member, only: [:show, :report]
      before_action :ensure_is_creator, only: [:destroy]

      after_action :set_last_message_read, only: [:show]

      def index
        conversations = Entourage.joins(:members)
          .includes(:chat_messages)
          .where.not(chat_messages: { id: nil })
          .where(group_type: [:conversation, :outing])
          .where('join_requests.user_id = ?', current_user.id)
          .merge(JoinRequest.accepted)
          .order(updated_at: :desc)
          .page(page).per(per)

        render json: conversations, root: :conversations, each_serializer: ::V1::ConversationSerializer, scope: {
          user: current_user
        }
      end

      def privates
        privates = Entourage.joins(:join_requests)
          .includes(:join_requests, { user: :partner })
          .where(group_type: :conversation)
          .where('join_requests.user_id = ?', current_user.id)
          .where('join_requests.status = ?', :accepted)
          .order(updated_at: :desc)
          .page(params[:page] || 1).per(per)

        render json: privates, root: :conversations, each_serializer: ::V1::ConversationSerializer, scope: {
          user: current_user, include_last_message: true
        }
      end

      # to be deprecated
      def private
        entourages = Entourage.joins(:join_requests)
          .includes(:join_requests, { user: :partner })
          .where(group_type: :conversation)
          .where('join_requests.user_id = ?', current_user.id)
          .where('join_requests.status = ?', :accepted)
          .order(updated_at: :desc)
          .page(params[:page] || 1).per(per)

        render json: entourages, root: :entourages, each_serializer: ::V1::EntourageSerializer, scope: {
          user: current_user, include_last_message: true
        }
      end

      def outings
        outings = Entourage.joins(:join_requests)
          .includes(:join_requests, { user: :partner })
          .where(group_type: [:outing])
          .where('join_requests.user_id = ?', current_user.id)
          .where('join_requests.status = ?', :accepted)
          .order(updated_at: :desc)
          .page(params[:page] || 1).per(per)

        render json: outings, root: :conversations, each_serializer: ::V1::ConversationSerializer, scope: {
          user: current_user, include_last_message: true
        }
      end

      # to be deprecated
      def group
        entourages = Entourage.joins(:join_requests)
          .includes(:join_requests, { user: :partner })
          .where(group_type: [:outing])
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
          .select(:id, :user_id, :group_type)
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
        render json: @conversation, root: :conversation, serializer: ::V1::ConversationHomeSerializer, scope: {
          user: current_user
        }
      end

      def create
        participant_ids = [conversation_params[:user_id], current_user.id]

        unless @conversation = Entourage.findable.find_by(uuid_v2: ConversationService.hash_for_participants(participant_ids))
          @conversation = ConversationService.build_conversation(participant_ids: participant_ids, creator_id: current_user.id)
          @conversation.create_from_join_requests!
        end

        render json: @conversation, status: 201, root: :conversation, serializer: ::V1::ConversationHomeSerializer, scope: {
          user: current_user
        }
      rescue => e
        render json: { message: 'unable to create conversation' }, status: :bad_request
      end

      def destroy
        EntourageServices::Deleter.new(user: current_user, entourage: @conversation).delete do |on|
          on.success do |conversation|
            render json: conversation, root: :conversation, status: 200, serializer: ::V1::ConversationHomeSerializer, scope: { user: current_user }
          end

          on.failure do |conversation|
            render json: {
              message: "Could not delete conversation", reasons: conversation.errors.full_messages
            }, status: :bad_request
          end

          on.not_authorized do
            render json: {
              message: "You are not authorized to delete this conversation"
            }, status: :unauthorized
          end
        end
      end

      def report
        unless report_params[:signals].present?
          render json: {
            code: 'CANNOT_REPORT_CONVERSATION',
            message: 'signals is required'
          }, status: :bad_request and return
        end

        SlackServices::SignalConversation.new(
          conversation: @conversation,
          reporting_user: current_user,
          signals: report_params[:signals],
          message: report_params[:message]
        ).notify

        head :created
      end

      private

      def page
        params[:page] || 1
      end

      def set_conversation
        @conversation = Entourage.find_by_id_through_context(params[:id], params)

        render json: { message: 'Could not find conversation' }, status: 400 unless @conversation.present?
      end

      def conversation_params
        params.require(:conversation).permit(:user_id)
      end

      def ensure_is_member
        render json: { message: 'unauthorized user' }, status: :unauthorized unless join_request
      end

      def ensure_is_creator
        render json: { message: 'unauthorized user' }, status: :unauthorized unless @conversation.user_id == current_user.id
      end

      def join_request
        @join_request ||= JoinRequest.where(joinable: @conversation, user: @current_user, status: :accepted).first
      end

      def set_last_message_read
        return unless join_request

        join_request.set_chat_messages_as_read
      end

      def report_params
        params.require(:report).permit(:message, signals: [])
      end
    end
  end
end

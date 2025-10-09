module Api
  module V1
    module Conversations
      class ImagesController < Api::V1::BaseController
        before_action :set_conversation, only: [:index, :show]
        before_action :set_chat_message, only: [:show]
        before_action :ensure_is_member, only: [:index, :show]

        def index
          chat_messages = @conversation.chat_messages.visible.with_image.order(created_at: :desc).page(page).per(per)

          # manual preloads
          chat_messages.tap do |messages|
            ::Preloaders::ChatMessage.preload_images(messages, scope: ImageResizeAction.with_size(:medium))
          end

          render json: chat_messages, root: "images", each_serializer: ::V1::Images::ChatMessageSerializer
        end

        def show
          @chat_message.preload_image_url = @chat_message.image_url_with_size(:high)

          render json: @chat_message, root: :image, serializer: ::V1::Images::ChatMessageSerializer
        end

        private

        def set_conversation
          @conversation = Entourage.find_by_id_through_context(params[:conversation_id], params)

          render json: { message: 'Could not find conversation' }, status: 400 unless @conversation.present?
        end

        def set_chat_message
          @chat_message = @conversation.chat_messages.find_by_id(params[:id])

          return render json: { message: 'Could not find chat_message in that conversation' }, status: 400 unless @chat_message.present?

          render json: { message: 'Image is not visible' }, status: 400 unless @chat_message.visible?
        end

        def ensure_is_member
          render json: { message: 'unauthorized' }, status: :unauthorized unless join_request
        end

        def join_request
          @join_request ||= JoinRequest.where(joinable: @conversation, user: current_user, status: :accepted).first
        end

        def page
          params[:page] || 1
        end
      end
    end
  end
end

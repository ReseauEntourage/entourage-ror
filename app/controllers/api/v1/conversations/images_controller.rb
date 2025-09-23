module Api
  module V1
    module Conversations
      class ImagesController < Api::V1::BaseController
        before_action :set_conversation, only: [:index]
        before_action :ensure_is_member, only: [:index]

        def index
          chat_messages = @conversation.chat_messages.with_image.page(page).per(per)

          # manual preloads
          chat_messages.tap do |messages|
            ::Preloaders::ChatMessage.preload_images(messages, scope: ImageResizeAction.with_size(:medium))
          end

          render json: { images: chat_messages.map(&:preload_image_url) }
        end

        private

        def set_conversation
          @conversation = Entourage.find_by_id_through_context(params[:conversation_id], params)

          render json: { message: 'Could not find conversation' }, status: 400 unless @conversation.present?
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

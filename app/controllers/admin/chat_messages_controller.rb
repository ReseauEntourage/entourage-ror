module Admin
  class ChatMessagesController < Admin::BaseController
    skip_before_action :verify_authenticity_token, only: [:photo_upload_success]

    before_action :set_chat_message

    def show
      respond_to do |format|
        format.js
      end
    end

    def update
      ChatServices::Updater.new(user: current_user, chat_message: @chat_message, params: chat_message_params).update(true) do |on|
        on.success do |chat_message|
          respond_to do |format|
            format.js
          end
        end
      end
    end

    def cancel_update
      respond_to do |format|
        format.js
      end
    end

    def edit_photo
      respond_to do |format|
        format.js
      end
    end

    def cancel_update_photo
      respond_to do |format|
        format.js
      end
    end

    def delete_photo
      @chat_message.update_attribute(:image_url, nil)

      respond_to do |format|
        format.js
      end
    end

    def photo_upload_success
      @chat_message = ChatMessageUploader.handle_success(params)

      render partial: 'display_image'
    end

    def edit_video
      respond_to do |format|
        format.js
      end
    end

    def cancel_update_video
      respond_to do |format|
        format.js
      end
    end

    def update_video
      @chat_message.update(video_url_params)

      respond_to do |format|
        format.js
      end
    end

    def delete_video
      @chat_message.update_attribute(:video_url, nil)

      respond_to do |format|
        format.js
      end
    end

    private

    def set_chat_message
      @chat_message = ChatMessage.find(params[:id])
    end

    def chat_message_params
      params.require(:chat_message).permit(:content)
    end

    def video_url_params
      params.require(:chat_message).permit(:video_url)
    end
  end
end

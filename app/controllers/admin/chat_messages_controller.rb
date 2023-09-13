module Admin
  class ChatMessagesController < Admin::BaseController
    before_action :set_chat_message

    def show
      respond_to do |format|
        format.js
      end
    end

    def update
      @chat_message.assign_attributes(chat_message_params)

      if @chat_message.save
        respond_to do |format|
          format.js
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

    def photo_upload_success
      image = ChatMessageUploader.handle_success(params)
      respond_to do |format|
        format.js
        format.html
      end
    end

    private

    def set_chat_message
      @chat_message = ChatMessage.find(params[:id])
    end

    def chat_message_params
      params.require(:chat_message).permit(:content)
    end
  end
end

module Admin
  class ChatMessagesController < Admin::BaseController
    def show
      @chat_message = ChatMessage.find(params[:id])

      respond_to do |format|
        format.js
      end
    end

    def update
      @chat_message = ChatMessage.find(params[:id])
      @chat_message.assign_attributes(chat_message_params)

      if @chat_message.save
        respond_to do |format|
          format.js
        end
      end
    end

    def cancel_update
      @chat_message = ChatMessage.find(params[:id])

      respond_to do |format|
        format.js
      end
    end

    private

    def chat_message_params
      params.require(:chat_message).permit(:content)
    end
  end
end

module Admin
  class MessagesController < Admin::BaseController
    def index
      @messages = Message.order('created_at DESC').page(params[:page]).per(25)
    end

    def destroy
      Message.find(params[:id]).destroy
      redirect_to admin_messages_path
    end
  end
end

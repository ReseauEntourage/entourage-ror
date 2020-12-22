module Admin
  class ConversationMessageBroadcastsController < Admin::BaseController
    layout 'admin_large'

    def index
      @conversation_message_broadcasts = ConversationMessageBroadcast.all

      @area = params[:area]
      @goal = params[:goal]
    end

    def new
      @conversation_message_broadcast = ConversationMessageBroadcast.new
    end

    def create
      @conversation_message_broadcast = ConversationMessageBroadcast.new(conversation_message_broadcast_params)
      if @conversation_message_broadcast.save
        redirect_to edit_admin_conversation_message_broadcast_path(@conversation_message_broadcast)
      else
        render :new
      end
    end

    def edit
      @conversation_message_broadcast = ConversationMessageBroadcast.find(params[:id])
    end

    def update
      @conversation_message_broadcast = ConversationMessageBroadcast.find(params[:id])
      @conversation_message_broadcast.assign_attributes(conversation_message_broadcast_params)

      if params.key?(:unarchive)
        @conversation_message_broadcast.archived_at = nil
      elsif params.key?(:archive)
        @conversation_message_broadcast.archived_at = Time.now
      end

      if @conversation_message_broadcast.save
        redirect_to edit_admin_conversation_message_broadcast_path(@conversation_message_broadcast)
      else
        @conversation_message_broadcast.status = @conversation_message_broadcast.status_was
        render :edit
      end
    end

    def send
      @conversation_message_broadcast = ConversationMessageBroadcast.find(params[:id])
    end

    private

    def conversation_message_broadcast_params
      params.require(:conversation_message_broadcast).permit(
        :moderation_area_id, :moderation_area, :goal, :content, :title
      )
    end
  end
end

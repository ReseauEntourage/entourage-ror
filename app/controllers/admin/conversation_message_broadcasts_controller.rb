module Admin
  class ConversationMessageBroadcastsController < Admin::BaseController
    layout 'admin_large'

    def index
      @goal = params[:goal].presence&.to_sym || :all
      @area = params[:area].presence&.to_sym || :all
      @status = params[:status].presence&.to_sym || :draft
      @areas = ModerationArea.by_slug

      @conversation_message_broadcasts = ConversationMessageBroadcast.where(status: @status)

      @conversation_message_broadcasts = @conversation_message_broadcasts.where(goal: @goal) if @goal and @goal != :all
      @conversation_message_broadcasts = @conversation_message_broadcasts.where(area: @area) if @area and @area != :all
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

      if params.key?(:archive)
        @conversation_message_broadcast.status = :archived
      end

      if @conversation_message_broadcast.save
        redirect_to edit_admin_conversation_message_broadcast_path(@conversation_message_broadcast)
      else
        @conversation_message_broadcast.status = @conversation_message_broadcast.status_was
        render :edit
      end
    end

    def clone
      @conversation_message_broadcast = ConversationMessageBroadcast.find(params[:id]).clone

      render :new
    end

    def broadcast
      @conversation_message_broadcast = ConversationMessageBroadcast.find(params[:id])
      @conversation_message_broadcast.update_attribute(:status, :sending)

      ConversationMessageBroadcastJob.perform_later(
        @conversation_message_broadcast.id,
        current_admin.id,
        @conversation_message_broadcast.user_ids,
        @conversation_message_broadcast.content
      )

      redirect_to edit_admin_conversation_message_broadcast_path(@conversation_message_broadcast)
    end

    private

    def conversation_message_broadcast_params
      params.require(:conversation_message_broadcast).permit(
        :area, :goal, :content, :title
      )
    end
  end
end

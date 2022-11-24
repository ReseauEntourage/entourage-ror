module Admin
  class ConversationMessageBroadcastsController < Admin::BaseController
    layout 'admin_large'

    def index
      @params = params.permit([:status, :area, :goal]).to_h
      @goal = params[:goal].presence&.to_sym || :all
      @area = params[:area].presence&.to_sym || :all
      @status = params[:status].presence&.to_sym || :draft

      @conversation_message_broadcasts = ConversationMessageBroadcast.with_status(@status).order(:created_at)

      @conversation_message_broadcasts = @conversation_message_broadcasts.where(goal: @goal) if @goal && @goal != :all
      @conversation_message_broadcasts = @conversation_message_broadcasts.with_moderation_area(@area.to_s) if @area && @area != :all
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

    def kill
      @conversation_message_broadcast = ConversationMessageBroadcast.find(params[:id]).delete_jobs
      @conversation_message_broadcast.update_attribute(:status, :sent)

      redirect_to admin_conversation_message_broadcasts_path(status: :sending)
    end

    def broadcast
      @conversation_message_broadcast = ConversationMessageBroadcast.find(params[:id])

      unless @conversation_message_broadcast.sent? || @conversation_message_broadcast.sending?
        @conversation_message_broadcast.update_attribute(:status, :sent)

        ConversationMessageBroadcastJob.perform_later(
          @conversation_message_broadcast.id,
          current_admin.id,
          @conversation_message_broadcast.content
        )
      end

      redirect_to edit_admin_conversation_message_broadcast_path(@conversation_message_broadcast)
    end

    private

    def conversation_message_broadcast_params
      params.require(:conversation_message_broadcast).permit(
        :area_type, :goal, :content, :title, areas: []
      )
    end
  end
end

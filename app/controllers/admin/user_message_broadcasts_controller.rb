module Admin
  class UserMessageBroadcastsController < Admin::BaseController
    layout 'admin_large'

    def index
      @params = params.permit([:status, :area, :goal]).to_h
      @goal = params[:goal].presence&.to_sym || :all
      @area = params[:area].presence&.to_sym || :all
      @status = params[:status].presence&.to_sym || :draft

      @user_message_broadcasts = UserMessageBroadcast.with_status(@status).order(created_at: :desc)

      @user_message_broadcasts = @user_message_broadcasts.where(goal: @goal) if @goal && @goal != :all
      @user_message_broadcasts = @user_message_broadcasts.with_moderation_area(@area.to_s) if @area && @area != :all
      @user_message_broadcasts = @user_message_broadcasts.page(page).per(per)
    end

    def new
      @user_message_broadcast = UserMessageBroadcast.new
    end

    def create
      @user_message_broadcast = UserMessageBroadcast.new(user_message_broadcast_params)
      if @user_message_broadcast.save
        redirect_to edit_admin_user_message_broadcast_path(@user_message_broadcast)
      else
        render :new
      end
    end

    def edit
      @user_message_broadcast = UserMessageBroadcast.find(params[:id])
    end

    def update
      @user_message_broadcast = UserMessageBroadcast.find(params[:id])
      @user_message_broadcast.assign_attributes(user_message_broadcast_params)

      if params.key?(:archive)
        @user_message_broadcast.status = :archived
      end

      if @user_message_broadcast.save
        redirect_to edit_admin_user_message_broadcast_path(@user_message_broadcast)
      else
        @user_message_broadcast.status = @user_message_broadcast.status_was
        render :edit
      end
    end

    def clone
      @user_message_broadcast = UserMessageBroadcast.find(params[:id]).clone

      render :new
    end

    def kill
      @user_message_broadcast = UserMessageBroadcast.find(params[:id]).delete_jobs
      @user_message_broadcast.update_attribute(:status, :sent)

      redirect_to admin_user_message_broadcasts_path(status: :sending)
    end

    def broadcast
      @user_message_broadcast = UserMessageBroadcast.find(params[:id])

      unless @user_message_broadcast.sent? || @user_message_broadcast.sending?
        @user_message_broadcast.update_attribute(:status, :sent)

        ConversationMessageBroadcastJob.perform_later(
          @user_message_broadcast.id,
          current_admin.id,
          @user_message_broadcast.content
        )
      end

      redirect_to edit_admin_user_message_broadcast_path(@user_message_broadcast)
    end

    private

    def user_message_broadcast_params
      params.require(:user_message_broadcast).permit(
        :area_type, :goal, :content, :title, areas: []
      )
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end

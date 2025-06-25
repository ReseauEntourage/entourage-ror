module Admin
  class SmalltalksController < Admin::BaseController
    before_action :set_smalltalk, only: [:show, :show_members, :show_messages, :message]

    def index
      @smalltalks = Smalltalk.includes(user_smalltalks: { user: :address }).order(updated_at: :desc).page(page).per(per)

      @chart_data = ChatMessage.where(
        messageable_type: 'Smalltalk',
        messageable_id: @smalltalks.pluck(:id),
        created_at: 7.days.ago.beginning_of_day..
      ).group(:messageable_id, "DATE(created_at)::text")
       .count

      @max_messages_per_day = @chart_data.values.max || 0
      @max_messages_per_day = (@max_messages_per_day * 1.1).ceil
    end

    def show
    end

    def show_members
      @members = @smalltalk.accepted_members.page(page).per(per)
    end

    def show_messages
      @messages = @smalltalk.chat_messages.order(created_at: :desc).page(page).per(per).includes(:user, :survey, :translation)
    end

    # POST
    def message
      ChatServices::ChatMessageBuilder.new(
        params: chat_messages_params,
        user: current_user,
        joinable: @smalltalk,
        join_request: nil
      ).create do |on|
        on.success do |message|
          redirect_to show_messages_admin_smalltalk_path(@smalltalk)
        end

        on.failure do |message|
          redirect_to show_messages_admin_smalltalk_path(@smalltalk), alert: "Erreur lors de l'envoi du message : #{message.errors.full_messages.to_sentence}"
        end
      end
    end

    private

    def set_smalltalk
      @smalltalk = Smalltalk.find(params[:id])
    end

    def chat_messages_params
      params.require(:chat_message).permit(:content, :parent_id)
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end

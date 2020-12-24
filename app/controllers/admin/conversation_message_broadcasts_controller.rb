module Admin
  class ConversationMessageBroadcastsController < Admin::BaseController
    layout 'admin_large'

    def index
      @goal = params[:goal].presence&.to_sym || :all
      @area = params[:area].presence&.to_sym || :all
      @archived = params[:archived].presence || false
      @areas = ModerationArea.by_slug

      @conversation_message_broadcasts =
        if @archived
          ConversationMessageBroadcast.archived
        else
          ConversationMessageBroadcast.not_archived
        end

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

    def broadcast
      conversation_message_broadcast = ConversationMessageBroadcast.find(params[:id])
      content = conversation_message_broadcast.content
      user = current_admin

      conversation_message_broadcast.users.each do |recipient|
        conversation = find_conversation recipient.id, user_id: user.id

        join_request =
          if conversation.new_record?
            conversation.join_requests.to_a.find { |r| r.user_id == user.id }
          else
            user.join_requests.accepted.find_by!(joinable: conversation)
          end

        chat_builder = ChatServices::ChatMessageBuilder.new(
            user: user,
            joinable: conversation,
            join_request: join_request,
            params: {content: content}
        )

        chat_builder.create do |on|
          on.success do |message|
            join_request.update_column(:last_message_read, message.created_at)
            # conversation_message_broadcast.succeeded(user, recipient)
          end

          on.failure do |message|
            # conversation_message_broadcast.failed(user, recipient)
          end
        end
      end
    end

    private

    def conversation_message_broadcast_params
      params.require(:conversation_message_broadcast).permit(
        :area, :goal, :content, :title
      )
    end

    def find_conversation recipient_id, user_id:
      participants = [recipient_id, user_id]
      uuid_v2 = ConversationService.hash_for_participants(participants)

      Entourage.where(group_type: :conversation).find_by(uuid_v2: uuid_v2) ||
        ConversationService.build_conversation(participant_ids: participants)
    end
  end
end

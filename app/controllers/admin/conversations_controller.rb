module Admin
  class ConversationsController < Admin::BaseController
    layout 'admin_large'

    def index
      @user = moderator

      @conversations = Entourage
        .where(group_type: :conversation)
        .joins(:join_requests)
        .merge(@user.join_requests.accepted)
        .joins("join last_chat_messages on last_chat_messages.entourage_id = entourages.id")
        .order("last_chat_messages.created_at desc")
        .select(%(
          entourages.*,
          last_chat_messages.id as last_message_id,
          last_message_read is null or last_message_read < last_chat_messages.created_at as unread
        ))
        .page(params[:page])
        .per(50)

      @last_message = Hash[ChatMessage.where(id: @conversations.map(&:last_message_id)).map { |m| [m.messageable_id, m] }]

      @recipient_ids = JoinRequest.accepted.where(joinable_type: :Entourage, joinable_id: @conversations.map(&:id)).where.not(user_id: @user.id).pluck(:joinable_id, :user_id).group_by(&:first).each { |_, a| a.replace a.map(&:last) }

      @users = Hash[(User.where(id: @recipient_ids.values.map{ |a| a.first(3) }.flatten + @last_message.values.map(&:user_id)).uniq).select(:id, :first_name, :last_name).map { |u| [u.id, u] }]
    end

    def show
      user = moderator
      @conversation = find_conversation params[:id], user: user

      @recipients =
        if @conversation.new_record?
          User.where(id: @conversation.join_requests.map(&:user_id) - [moderator.id])
        else
          @conversation.members.where.not(id: moderator.id).merge(JoinRequest.accepted)
        end

      @recipients = @recipients.select(:id, :first_name, :last_name).to_a
      @chat_messages = @conversation.chat_messages.order(:created_at).includes(:user)
      @messages_author = moderator
    end

    def message
      user = moderator
      conversation = find_conversation params[:id], user: user

      join_request =
        if conversation.new_record?
          conversation.join_requests.to_a.find { |r| r.user_id == user.id }
        else
          user.join_requests.accepted.find_by!(joinable: conversation)
        end

      chat_builder = ChatServices::ChatMessageBuilder.new(
        params: chat_messages_params,
        user: user,
        joinable: conversation,
        join_request: join_request
      )

      chat_builder.create do |on|
        on.success do |message|
          join_request.touch(:last_message_read)
          redirect_to admin_conversation_path(conversation)
        end

        on.failure do |message|
          redirect_to admin_conversation_path(conversation), alert: "Erreur lors de l'envoi du message : #{message.errors.full_messages.to_sentence}"
        end
      end
    end

    private

    def moderator
      @moderator ||= User.find_by email: 'guillaume@entourage.social', community: :entourage
    end

    def chat_messages_params
      params.require(:chat_message).permit(:content)
    end

    def find_conversation id, user:
      if ConversationService.list_uuid?(id)
        participant_ids = ConversationService.participant_ids_from_list_uuid(params[:id])
        raise ActiveRecord::RecordNotFound unless participant_ids.include?(user.id.to_s)
        hash_uuid = ConversationService.hash_for_participants(participant_ids)
        Entourage.find_by(uuid_v2: hash_uuid) ||
          ConversationService.build_conversation(participant_ids: participant_ids)
      else
        user.entourage_participations.where(group_type: :conversation).find_by_id_or_uuid(params[:id])
      end
    end
  end
end

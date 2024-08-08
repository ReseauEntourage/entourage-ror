module Admin
  class ConversationsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_conversation, only: [:chat_messages, :show_members, :message, :invite, :unjoin, :read_status, :archive_status]
    before_action :set_recipients, only: [:show_members]

    def index
      @params = params.permit([:filter])

      @conversations = Entourage
        .includes(:user)
        .joins(:join_requests)
        .where(group_type: :conversation)
        .search_by_member(params[:search])
        .merge(current_admin.join_requests.accepted)
        .select(%(
          entourages.*,
          last_message_read < feed_updated_at or last_message_read is null as unread
        ))
        .order("feed_updated_at desc")
        .page(params[:page])
        .per(50)

      params.delete(:filter) unless params[:filter].in?(['archived', 'unread', 'multiple'])

      @conversations = if params[:filter] == 'archived'
        @conversations.where("archived_at >= feed_updated_at")
      else
        @conversations.where("archived_at < feed_updated_at or archived_at is null")
      end

      @conversations = @conversations.where("last_message_read < feed_updated_at or last_message_read is null") if params[:filter] == 'unread'
      @conversations = @conversations.where("number_of_people > 2") if params[:filter] == 'multiple'

      respond_to do |format|
        format.js
        format.html
      end
    end

    def chat_messages
      @chat_messages = @conversation.chat_messages.order(created_at: :asc)

      respond_to do |format|
        format.js
        format.html { render partial: 'chat_messages', locals: { conversation: @conversation, chat_messages: @chat_messages, tab: :chat_messages } }
      end
    end

    def show_members
      @join_requests = @conversation.join_requests.accepted.includes(:user)

      respond_to do |format|
        format.js
        format.html { render partial: 'show_members', locals: { join_requests: @join_requests, tab: :show_members } }
      end
    end

    def message
      join_request = if @conversation.new_record?
        @conversation.join_requests.to_a.find { |r| r.user_id == current_admin.id }
      else
        current_admin.join_requests.accepted.find_by!(joinable: @conversation)
      end

      chat_builder = ChatServices::ChatMessageBuilder.new(
        params: chat_messages_params,
        user: current_admin,
        joinable: @conversation,
        join_request: join_request
      )

      chat_builder.create do |on|
        on.success do |message|
          join_request.update_column(:last_message_read, message.created_at)
          redirect_to admin_conversation_path(@conversation)
        end

        on.failure do |message|
          redirect_to admin_conversation_path(params[:id]), alert: "Erreur lors de l'envoi du message : #{message.errors.full_messages.to_sentence}"
        end
      end
    end

    def destroy_message
      @chat_message = ChatMessage.find(params[:id])

      ChatServices::Deleter.new(user: current_user, chat_message: @chat_message).delete(true) do |on|
        redirection = chat_messages_admin_conversation_path(@chat_message.messageable)

        on.success do |chat_message|
          @conversation = @chat_message.messageable
          @chat_messages = @conversation.chat_messages.order(created_at: :asc)

          respond_to do |format|
            format.js { render :chat_messages }
            format.html { render partial: 'chat_messages', locals: { conversation: @conversation, chat_messages: @chat_messages } }
          end
        end

        on.failure do |chat_message|
          redirect_to redirection, alert: chat_message.errors.full_messages
        end

        on.not_authorized do
          redirect_to redirection, alert: "You are not authorized to delete this chat_message"
        end
      end
    end

    def invite
      user = User.find_by_id_or_phone(params[:user_id])
      join_request = JoinRequest.where(joinable: @conversation, user: user).first

      return redirect_to admin_conversation_path(params[:id]), notice: "L'utilisateur '#{user.full_name}' fait déjà partie de la conversation" if join_request.present? && join_request.accepted?

      if join_request.present?
        join_request.status = :accepted
      else
        join_request = JoinRequest.new(joinable: @conversation, user: user, role: :participant, status: :accepted)
      end

      if join_request.save
        respond_to do |format|
          format.js { render :show_members }
          format.html { redirect_to admin_conversation_path(params[:id]), notice: "L'utilisateur '#{user.full_name}' a été ajouté à la conversation" }
        end
      else
        redirect_to admin_conversation_path(params[:id]), alert: "L'utilisateur '#{params[:user_id]}' n'a pas pu être ajouté à la conversation"
      end
    end

    def unjoin
      user = User.find(params[:user_id])
      join_request = JoinRequest.where(joinable: @conversation, user: user).first

      return redirect_to admin_conversation_path(params[:id]), notice: "L'utilisateur '#{user.full_name}' ne fait déjà pas partie de la conversation" unless join_request.present? && join_request.accepted?

      if join_request.update_attribute(:status, :cancelled)
        respond_to do |format|
          format.js { render :show_members }
          format.html { redirect_to admin_conversation_path(params[:id]), notice: "L'utilisateur '#{user.full_name}' a été retiré de la conversation" }
        end
      else
        redirect_to admin_conversation_path(params[:id]), alert: "L'utilisateur '#{user.full_name}' n'a pas pu être retiré de la conversation"
      end
    end

    def read_status
      status = params[:status]&.to_sym
      raise unless status.in?([:read, :unread])

      timestamp =
        case status
        when :read
          Time.now
        when :unread
          nil
        end

      JoinRequest.where(joinable: @conversation).update_all(last_message_read: timestamp)

      filters = {}
      filters[:filter] = :unread if status == :unread
      redirect_to admin_conversations_path(filters)
    end

    def archive_status
      status = params[:status]&.to_sym
      raise unless status.in?([:archived, :inbox])

      timestamp =
        case status
        when :archived
          Time.now
        when :inbox
          nil
        end

      JoinRequest.where(joinable: @conversation).update_all(archived_at: timestamp)

      redirect_to admin_conversations_path({ filter: :archived })
    end

    private

    def chat_messages_params
      params.require(:chat_message).permit(:content)
    end

    def set_conversation
      @conversation = find_conversation(params[:id], user: current_admin)
    end

    def set_recipients
      @recipients = if @conversation.new_record?
        User.where(id: @conversation.join_requests.map(&:user_id) - [current_admin.id])
      else
        @conversation.members.where.not(id: current_admin.id).merge(JoinRequest.accepted)
      end

      @recipients = @recipients.select(:id, :first_name, :last_name).to_a

      # if no recipient, it must be a conversation with self
      if @recipients.empty?
        @recipients = [current_admin]
      end
    end

    def find_conversation id, user:
      if ConversationService.list_uuid?(id)
        participant_ids = ConversationService.participant_ids_from_list_uuid(params[:id])

        raise ActiveRecord::RecordNotFound unless participant_ids.include?(user.id.to_s)

        hash_uuid = ConversationService.hash_for_participants(participant_ids)

        Entourage.find_by(uuid_v2: hash_uuid) ||
          ConversationService.build_conversation(participant_ids: participant_ids, creator_id: current_admin.id)
      else
        Entourage.where(group_type: :conversation).findable_by_id_or_uuid(params[:id])
      end
    end
  end
end

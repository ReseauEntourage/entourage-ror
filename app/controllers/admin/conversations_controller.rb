module Admin
  class ConversationsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_conversation, only: [:show, :show_members, :message, :invite, :unjoin, :read_status, :archive_status]
    before_action :set_recipients, only: [:show, :show_members]

    def index
      @params = params.permit([:filter])
      @user = current_admin

      @conversations = Entourage
        .where(group_type: :conversation)
        .joins(:join_requests)
        .merge(@user.join_requests.accepted)
        .select(%(
          entourages.*,
          last_message_read < feed_updated_at or last_message_read is null as unread
        ))
        .order("feed_updated_at desc")
        .page(params[:page])
        .per(50)

      params.delete(:filter) unless params[:filter].in?(['archived', 'unread'])

      if params[:filter] == 'archived'
        @conversations = @conversations
          .where("archived_at >= feed_updated_at")
      else
        @conversations = @conversations
          .where("archived_at < feed_updated_at or archived_at is null")
      end

      if params[:filter] == 'unread'
        @conversations = @conversations
          .where("last_message_read < feed_updated_at or last_message_read is null")
      end

      @last_message =
        ChatMessage
        .select('distinct on (messageable_id) *')
        .where(messageable_type: :Entourage)
        .where(messageable_id: @conversations.map(&:id))
        .order(:messageable_id, created_at: :desc)

      @last_message = Hash[@last_message.map { |m| [m.messageable_id, m] }]

      @recipient_ids = JoinRequest.accepted.where(joinable_type: :Entourage, joinable_id: @conversations.map(&:id)).where.not(user_id: @user.id).pluck(:joinable_id, :user_id).group_by(&:first).each { |_, a| a.replace a.map(&:last) }
      @recipient_ids.default = [@user.id] # if no recipient, it must be a conversation with self

      @users = Hash[User.where(
        id: @recipient_ids.values.map{ |a| a.first(3) }.flatten + @last_message.values.map(&:user_id)
      ).select(:id, :first_name, :last_name).uniq.map { |u| [u.id, u] }]
    end

    def show
      join_requests = @conversation.join_requests.accepted.to_a
      join_request = join_requests.find { |r| r.user_id == current_admin.id }

      @new_conversation = join_request.nil?

      @read = join_request.present? &&
              join_request.last_message_read.present? &&
              join_request.last_message_read >= (@conversation.feed_updated_at || @conversation.updated_at)
      @archived = join_request.present? &&
                  join_request.archived_at.present? &&
                  join_request.archived_at >= (@conversation.feed_updated_at || @conversation.updated_at)

      @chat_messages = @conversation.chat_messages.order(:created_at).includes(:user)

      reads = join_requests
        .reject { |r| r.last_message_read.nil? || r.user_id == current_admin.id }
        .reject { |r| r.last_message_read < @chat_messages.first.created_at if @chat_messages.any? }
        .sort_by(&:last_message_read)

      @last_reads = Hash.new { |h, k| h[k] = [] }

      (@chat_messages + [nil]).each_cons(2) do |message, next_message|
        while reads.any? &&
              reads.first.last_message_read >= message.created_at &&
              (!next_message ||
               reads.first.last_message_read < next_message.created_at) do
          @last_reads[message.id].push reads.shift
        end
      end

      @messages_author = current_admin if join_request.present? || @conversation.new_record?
    end

    def show_members
      @join_requests = @conversation.join_requests.accepted.includes(:user)
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
        redirect_to admin_conversation_path(params[:id]), notice: "L'utilisateur '#{user.full_name}' a été ajouté à la conversation"
      else
        redirect_to admin_conversation_path(params[:id]), alert: "L'utilisateur '#{params[:user_id]}' n'a pas pu être ajouté à la conversation"
      end
    end

    def unjoin
      user = User.find(params[:user_id])
      join_request = JoinRequest.where(joinable: @conversation, user: user).first

      return redirect_to admin_conversation_path(params[:id]), notice: "L'utilisateur '#{user.full_name}' ne fait déjà pas partie de la conversation" unless join_request.present? && join_request.accepted?

      if join_request.update_attribute(:status, :cancelled)
        redirect_to admin_conversation_path(params[:id]), notice: "L'utilisateur '#{user.full_name}' a été retiré de la conversation"
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

      redirect_to admin_conversations_path()
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

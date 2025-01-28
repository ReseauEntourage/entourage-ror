module Admin
  class ConversationsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_conversation, only: [:show, :chat_messages, :prepend_chat_messages, :show_members, :message, :invite, :unjoin, :read_status, :archive_status]
    before_action :set_recipients, only: [:show, :show_members]

    def index
      @params = params.permit([:filter])

      @conversations = Conversation
        .includes(:user)
        .joins(:join_requests)
        .search_by_id(params[:search])
        .search_by_member(params[:search])
        .with_chat_messages
        .merge(current_admin.join_requests.accepted)
        .select("entourages.*, (unread_messages_count > 0) as unread")
        .order("feed_updated_at desc")
        .page(params[:page])
        .per(50)

      params.delete(:filter) unless params[:filter].in?(['archived', 'unread'])

      @conversations = if params[:filter] == 'archived'
        @conversations.where("archived_at >= feed_updated_at")
      else
        @conversations.where("archived_at < feed_updated_at or archived_at is null")
      end

      @conversations = @conversations.where("unread_messages_count > 0") if params[:filter] == 'unread'

      respond_to do |format|
        format.js
        format.html
      end
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

      @chat_messages = @conversation.chat_messages.order(:created_at).includes(:user, :translation)

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

    def new
      @conversation = Conversation.new
    end

    def create
      participant_ids = (conversation_params[:member_ids] + [current_admin.id]).uniq

      if @conversation = Conversation.active.with_exact_members(participant_ids).first
        return redirect_to admin_conversations_path(search: @conversation.id), alert: "Une conversation identique existe déjà"
      end

      # create conversation
      @conversation = ConversationService.build_conversation(participant_ids: participant_ids, creator_id: current_admin.id)
      @conversation.create_from_join_requests!

      # create message
      ChatMessage.new(
        user: current_admin,
        messageable: @conversation,
        content: conversation_params[:message]
      ).save!

      # we need this value right now to get conversation displayable in index view
      @conversation.update_attribute(:number_of_root_chat_messages, 1)

      redirect_to admin_conversations_path
    rescue => e
      redirect_to admin_conversations_path, alert: "Une erreur a eu lieu : #{e}"
    end

    def chat_messages
      @chat_messages = @conversation.chat_messages.order(created_at: :desc).page(1).per(10)

      respond_to do |format|
        format.js
        format.html { render partial: 'chat_messages', locals: { conversation: @conversation, chat_messages: @chat_messages, tab: :chat_messages } }
      end
    end

    def prepend_chat_messages
      @current_page = params[:page] || 1
      @chat_messages = @conversation.chat_messages.order(created_at: :desc).page(@current_page).per(10)

      respond_to do |format|
        format.js
        format.html { render partial: 'prepend_chat_messages', locals: { conversation: @conversation, chat_messages: @chat_messages, tab: :chat_messages } }
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
          join_request.set_chat_messages_as_read_from(message.created_at)

          respond_to do |format|
            @chat_messages = [message]

            format.js { render :append_chat_messages }
            format.html { redirect_to admin_conversations_path }
          end
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
          @chat_messages = @conversation.chat_messages.order(created_at: :desc)

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

      join_request = JoinRequest.where(joinable: @conversation, user: current_admin).first

      if status == :read
        join_request.set_chat_messages_as_read
      else
        join_request.set_chat_messages_as_unread
      end

      redirect_to admin_conversations_path(filter: Rack::Utils.parse_query(URI(request.referer).query)['filter'])
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

    def conversation_params
      params.require(:conversation).permit(:message, member_ids: [])
    end

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

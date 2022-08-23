module V1
  class ConversationSerializer < ActiveModel::Serializer
    include AmsLazyRelationships::Core

    attributes :id,
               :type,
               :name,
               :image_url,
               :last_message,
               :number_of_unread_messages

    # admin, ambassador, coordinator, ethics_charter_signed, moderator, not_validated, visited, visitor
    attribute :roles, if: :private_conversation?

    lazy_relationship :last_chat_message
    lazy_relationship :chat_messages_count
    lazy_relationship :chat_messages
    lazy_relationship :join_requests

    def type
      return :private if private_conversation?
      return :contribution if object.contribution?

      :solicitation
    end

    def name
      return object.title unless private_conversation?

      UserPresenter.new(user: other_participant).display_name
    end

    def image_url
      return object.image_url unless private_conversation?

      UserServices::Avatar.new(user: other_participant).thumbnail_url
    end

    def last_message
      return unless last_chat_message.present?

      {
        text: last_chat_message.content,
        date: last_chat_message.created_at,
      }
    end

    def number_of_unread_messages
      return lazy_chat_messages_count&.count || 0 if current_join_request.last_message_read.nil?

      lazy_chat_messages.select do |chat_message|
        chat_message.created_at > current_join_request.last_message_read
      end.count
    end

    def roles
      other_participant.roles
    end

    # protected

    def private_conversation?
      object.group_type.in?(['conversation'])
    end

    def other_participant
      return unless private_conversation?

      @other_participant ||= object.members.find do |member|
        member.id != scope[:user]&.id
      end
    end

    def last_chat_message
      @last_chat_message ||= lazy_last_chat_message
    end

    def current_join_request
      # @fixme performance issue: we instanciate all records but we need only one
      @current_join_request ||=  lazy_join_requests.select do |join_request|
        join_request.user_id == scope[:user].id
      end.first
    end
  end
end

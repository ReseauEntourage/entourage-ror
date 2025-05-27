module V1
  class SmalltalkSerializer < ActiveModel::Serializer
    include AmsLazyRelationships::Core

    attributes :id,
      :uuid_v2,
      :type,
      :name,
      :subname,
      :image_url,
      :members_count,
      :last_message,
      :number_of_unread_messages,
      :has_personal_post,
      :members,
      :meeting_url

    lazy_relationship :last_chat_message
    lazy_relationship :chat_messages_count
    lazy_relationship :chat_messages
    lazy_relationship :join_requests

    def type
      :smalltalk
    end

    def name
      I18n.t('activerecord.attributes.smalltalk.object', lang: lang)
    end

    def subname
      nil
    end

    def image_url
      nil
    end

    def last_message
      return unless last_chat_message.present?

      {
        text: Mentionable.no_html(last_chat_message.content),
        date: last_chat_message.created_at,
      }
    end

    def number_of_unread_messages
      return unless current_join_request.present?
      return lazy_chat_messages_count&.count || 0 if current_join_request.last_message_read.nil?

      lazy_chat_messages.select do |chat_message|
        chat_message.created_at > current_join_request.last_message_read
      end.count
    end

    def has_personal_post
      return unless scope[:user]

      (lazy_chat_messages.pluck(:user_id) & [scope[:user].id]).any?
    end

    def members
      object.accepted_members.limit(5).map do |member|
        ::V1::Users::BasicSerializer.new(member, scope: scope).as_json
      end
    rescue
      []
    end

    private

    def lang
      return :fr unless scope[:user].present?

      scope[:user].lang
    end

    def last_chat_message
      @last_chat_message ||= lazy_last_chat_message
    end

    def current_join_request
      return unless scope[:user].present?

      # @fixme performance issue: we instanciate all records but we need only one
      @current_join_request ||=  lazy_join_requests.select do |join_request|
        join_request.user_id == scope[:user].id
      end.first
    end
  end
end

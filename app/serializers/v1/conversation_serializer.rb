module V1
  class ConversationSerializer < ActiveModel::Serializer
    include AmsLazyRelationships::Core
    include V1::Entourages::Blockers

    attributes :id,
               :uuid,
               :uuid_v2,
               :status,
               :type,
               :name,
               :subname,
               :image_url,
               :members_count,
               :last_message,
               :number_of_unread_messages,
               :has_personal_post

    attribute :user
    attribute :section, unless: :private_conversation?
    attribute :blockers, if: :private_conversation?

    has_many :members, serializer: ::V1::Users::BasicSerializer

    # @duplicated with V1::ConversationHomeSerializer
    def user
      return unless user = private_conversation? ? other_participant : object.user

      partner = user.partner

      {
        id: user.id,
        display_name: UserPresenter.new(user: user).display_name,
        avatar_url: UserServices::Avatar.new(user: user).thumbnail_url,
        partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: { minimal: true }, root: false).as_json,
        partner_role_title: user.partner_role_title.presence,
        roles: UserPresenter.new(user: user).public_targeting_profiles,
        moderator: user.admin?,
        birthday_today: user.birthday_today?
      }
    end

    def section
      return unless object.action?

      object.becomes(object.action_class).section
    end

    lazy_relationship :last_chat_message
    lazy_relationship :chat_message_authors
    lazy_relationship :join_requests

    def type
      return :private if private_conversation?
      return :outing if object.outing?
      return :contribution if object.contribution?

      :solicitation
    end

    def name
      return object.title unless private_conversation?
      return no_other_participant unless other_participant

      UserPresenter.new(user: other_participant).display_name
    end

    def subname
      return unless object.outing?

      object.starts_at
    end

    def image_url
      return object.image_url_with_size(:portrait_url, :small) unless private_conversation?
      return unless other_participant

      UserServices::Avatar.new(user: other_participant).thumbnail_url
    end

    def last_message
      return unless last_chat_message.present?

      {
        text: Mentionable.no_html(last_chat_message.content),
        date: last_chat_message.created_at,
      }
    end

    # @see JoinRequest#unread_messages_count, maintained async by UnreadChatMessageJob
    def number_of_unread_messages
      current_join_request&.unread_messages_count || 0
    end

    def has_personal_post
      return unless scope[:user]

      lazy_chat_message_authors.any? { |message| message.user_id == scope[:user].id }
    end

    # protected

    def private_conversation?
      object.conversation?
    end

    def other_participant
      @other_participant ||= object.interlocutor_of(scope[:user])
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

    def members
      if object.association(:accepted_members).loaded?
        object.accepted_members.first(5)
      else
        object.accepted_members.limit(5)
      end
    end

    private

    def no_other_participant
      I18n.t("conversations.participants.alone", lang: scope[:user].lang)
    end
  end
end

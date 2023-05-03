module V1
  class ConversationHomeSerializer < ActiveModel::Serializer
    include AmsLazyRelationships::Core
    include V1::Entourages::Blockers

    attributes :id,
      :uuid_v2,
      :status,
      :type,
      :name,
      :image_url,
      :creator,
      :member,
      :members_count,
      :chat_messages,
      :has_personal_post

    attribute :user, if: :private_conversation?
    attribute :section, unless: :private_conversation?
    attribute :author, unless: :private_conversation?
    attribute :blockers, if: :private_conversation?

    has_many :members, serializer: ::V1::Users::BasicSerializer

    lazy_relationship :chat_messages

    def type
      return :private if private_conversation?
      return :contribution if object.contribution?

      :solicitation
    end

    def name
      return object.title unless private_conversation?
      return unless other_participant

      UserPresenter.new(user: other_participant).display_name
    end

    def image_url
      return object.image_url unless private_conversation?
      return unless other_participant

      UserServices::Avatar.new(user: other_participant).thumbnail_url
    end

    def creator
      return false unless scope && scope[:user]

      object.user_id == scope[:user].id
    end

    def member
      return false unless scope && scope[:user]

      object.members.include? scope[:user]
    end

    def members_count
      object.members.count
    end

    def chat_messages
      object.chat_messages.ordered.limit(25).map do |chat_message|
        V1::ChatMessageHomeSerializer.new(chat_message, scope: { current_join_request: current_join_request }).as_json
      end
    end

    def has_personal_post
      return unless scope[:user]

      (lazy_chat_messages.pluck(:user_id) & [scope[:user].id]).any?
    end

    # @duplicated with V1::ConversationSerializer
    def user
      return unless user = other_participant

      partner = user.partner

      {
        id: user.id,
        display_name: UserPresenter.new(user: user).display_name,
        avatar_url: UserServices::Avatar.new(user: user).thumbnail_url,
        partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: { minimal: true }, root: false).as_json,
        partner_role_title: user.partner_role_title.presence,
        roles: UserPresenter.new(user: user).public_targeting_profiles
      }
    end

    def section
      object.becomes(object.contribution? ? Contribution : Solicitation).section
    end

    def author
      return unless object.user.present?

      {
        id: object.user.id,
        display_name: UserPresenter.new(user: object.user).display_name,
        avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
        created_at: object.user.created_at
      }
    end

    def private_conversation?
      object.group_type.in?(['conversation'])
    end

    private

    def current_join_request
      return unless scope[:user]

      @current_join_request ||= JoinRequest.where(joinable: object, user: scope[:user], status: :accepted).first
    end

    def other_participant
      @other_participant ||= object.interlocutor_of(scope[:user])
    end
  end
end

module V1
  class ConversationHomeSerializer < ActiveModel::Serializer
    attributes :id,
      :type,
      :name,
      :image_url,
      :member,
      :members_count,
      :chat_messages

    attribute :user, if: :private_conversation?
    attribute :section, unless: :private_conversation?

    has_many :members, serializer: ::V1::Users::BasicSerializer

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

    def user
      return unless user = other_participant

      partner = user.partner

      {
        id: user.id,
        display_name: UserPresenter.new(user: user).display_name,
        avatar_url: UserServices::Avatar.new(user: user).thumbnail_url,
        partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: { minimal: true }, root: false).as_json,
        partner_role_title: user.partner_role_title.presence,
        roles: user.roles
      }
    end

    def section
      object.becomes(object.contribution? ? Contribution : Solicitation).section
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
      return unless private_conversation?

      @other_participant ||= object.members.find do |member|
        member.id != scope[:user]&.id
      end
    end
  end
end

module V1
  class MembershipSerializer < ActiveModel::Serializer
    attributes :status,
      :joinable_status,
      :name,
      :subname,
      :joinable_type,
      :joinable_id,
      :number_of_people,
      :number_of_root_chat_messages,
      :number_of_unread_messages,
      :last_chat_message

    def joinable_status
      object.joinable.try(:status)
    end

    # joinable_types: Smalltalk, Neighborhood, Outing, Conversation
    def joinable_type
      return object.joinable_type unless object.entourage?

      return 'Outing' if object.outing?
      return 'Conversation' if object.conversation?

      object.joinable_type
    end

    def name
      return name_for_conversation if object.conversation?
      return name_for_smalltalk if object.smalltalk?

      object.joinable.try(:name) || object.joinable.try(:title)
    end

    def subname
      return unless object.outing?

      object.joinable.starts_at
    end

    def number_of_people
      object.joinable.try(:number_of_people)
    end

    def number_of_root_chat_messages
      object.joinable.try(:number_of_root_chat_messages)
    end

    def number_of_unread_messages
    end

    def last_chat_message
      return unless object.last_chat_message

      object.last_chat_message.content
    end

    private

    def name_for_conversation
      return unless other_participant

      UserPresenter.new(user: other_participant).display_name
    end

    def name_for_smalltalk
      return unless (other_participants = object.siblings.map(&:user)).any?

      I18n.t("activerecord.attributes.smalltalk.title_with_participants", lang: scope[:user].lang) % other_participants.map(&:first_name).join(', ')
    end

    def other_participant
      return unless object.conversation?

      @other_participant ||= object.joinable.interlocutor_of(scope[:user])
    end
  end
end

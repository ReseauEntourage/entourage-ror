module V1
  class MembershipSerializer < ActiveModel::Serializer
    attributes :status,
      :joinable_status,
      :name,
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
      object.joinable.try(:name) || object.joinable.try(:title)
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
    end
  end
end

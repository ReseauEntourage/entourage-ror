module V1
  class MembershipSerializer < ActiveModel::Serializer
    attributes :status,
      :joinable_status,
      :name,
      :subname,
      :image_url,
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

    def image_url
      return unless object.outing?

      outing = object.joinable

      outing.preload_image_url || outing.image_url_with_size(outing.metadata[:landscape_url], :medium)
    end

    def number_of_people
      object.joinable.try(:number_of_people)
    end

    def number_of_root_chat_messages
      object.joinable.try(:number_of_root_chat_messages)
    end

    def number_of_unread_messages
      object.unread_messages_count
    end

    def last_chat_message
      object.last_chat_message
    end

    private

    def name_for_conversation
      return no_other_participant unless other_participant

      UserPresenter.new(user: other_participant).display_name
    end

    def name_for_smalltalk
      return no_other_participant unless (other_participants = object.siblings.map(&:user)).any?

      I18n.t("activerecord.attributes.smalltalk.title_with_participants", lang: scope[:user].lang) % other_participants.map(&:first_name).join(', ')
    end

    def other_participant
      return unless object.conversation?

      @other_participant ||= object.joinable.interlocutor_of(scope[:user])
    end

    def no_other_participant
      I18n.t("conversations.participants.alone", lang: scope[:user].lang)
    end
  end
end

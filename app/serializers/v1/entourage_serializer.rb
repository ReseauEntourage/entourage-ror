module V1
  class EntourageSerializer < ActiveModel::Serializer
    attributes :id,
               :status,
               :title,
               :entourage_type,
               :join_status,
               :number_of_unread_messages,
               :number_of_people
    
    has_one :author
    has_one :location

    def author
      {
          id: object.user.id,
          name: object.user.first_name
      }
    end

    def location
      {
          latitude: object.longitude,
          longitude: object.longitude
      }
    end

    def join_status
      if current_entourage_user
        current_entourage_user.status
      else
        "not_requested"
      end
    end

    def number_of_unread_messages
      return nil unless current_entourage_user
      return object.chat_messages.count if current_entourage_user.last_message_read.nil?
      object.chat_messages.where("created_at > ?", current_entourage_user.last_message_read).count
    end

    def current_entourage_user
      #TODO : replace by sql request ?
      object.entourages_users.select {|entourage_user| entourage_user.user_id == scope.id}.first
    end
  end
end

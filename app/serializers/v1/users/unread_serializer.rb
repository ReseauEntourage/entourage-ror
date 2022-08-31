module V1
  module Users
    class UnreadSerializer < ActiveModel::Serializer
      attributes :id, :unread_count

      def unread_count
        UserServices::UnreadMessages.new(user: object).number_of_unread_messages
      end
    end
  end
end

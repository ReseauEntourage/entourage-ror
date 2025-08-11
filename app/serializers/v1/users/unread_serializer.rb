module V1
  module Users
    class UnreadSerializer < ActiveModel::Serializer
      attributes :id, :unread_count, :unread_conversations_count, :unread_neighborhoods_count

      # alias for unread_conversations_count
      def unread_count
        unread_conversations_count
      end

      # sums up unread conversations for:
      # - private conversations
      # - outing conversations
      # - smalltalks conversations
      def unread_conversations_count
        @unread_conversations_count ||= UserServices::UnreadMessages.new(
          user: object
        ).number_of_unread_for_joinable_types(:Entourage, :Smalltalk)
      end

      # sums up unread conversations for neighborhood conversations
      def unread_neighborhoods_count
        UserServices::UnreadMessages.new(
          user: object
        ).number_of_unread_for_joinable_types(:Neighborhood)
      end
    end
  end
end

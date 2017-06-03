module V1
  module Public
    class EntourageSerializer < ActiveModel::Serializer

      attributes :uuid,
                 :title,
                 :description,
                 :created_at,
                 :description,
                 :approximated_location

      has_one :author

      def created_at
        I18n.l(object.created_at, format: '%e %B')
      end

      def author
        return unless object.user
        entourage_author = object.user

        {
          display_name: entourage_author.first_name,
          avatar_url: UserServices::Avatar.new(user: entourage_author).thumbnail_url
        }
      end
    end
  end
end

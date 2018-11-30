module V1
  module Public
    class EntourageSerializer < ActiveModel::Serializer
      include V1::Entourages::Location

      attributes :uuid,
                 :title,
                 :group_type,
                 :description,
                 :created_at,
                 :location,
                 :approximated_location,
                 :number_of_people

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

      def filter(keys)
        if scope == :map
          [:title, :location]
        else
          keys - [:location]
        end
      end
    end
  end
end

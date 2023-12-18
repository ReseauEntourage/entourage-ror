module V1
  module Public
    class EntourageSerializer < ActiveModel::Serializer
      include V1::Entourages::Location

      attribute :uuid, unless: :map?
      attribute :title
      attribute :group_type, unless: :map?
      attribute :description, unless: :map?
      attribute :created_at, unless: :map?
      attribute :location, if: :map?
      attribute :approximated_location, unless: :map?
      attribute :number_of_people, unless: :map?

      has_one :author

      def map?
        scope == :map
      end

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

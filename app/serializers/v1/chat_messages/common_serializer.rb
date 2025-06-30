module V1
  module ChatMessages
    class CommonSerializer < GenericSerializer
      attributes :id,
       :uuid_v2,
       :content,
       :user,
       :created_at,
       :image_url,
       :read,
       :status

      def content
        return "" if object.deleted?
        return "" if object.offensive?

        object.content
      end
    end
  end
end

module V1
  module ChatMessages
    class CommonSerializer < GenericSerializer
      attributes :id,
       :uuid_v2,
       :content,
       :user,
       :created_at,
       :read,
       :status

      def content
        return if object.deleted?

        display_status = ""
        display_status = "[#{object.status}] "

        return "#{display_status}#{object.content}" if object.offensible? || object.offensive?

        object.content
      end
    end
  end
end

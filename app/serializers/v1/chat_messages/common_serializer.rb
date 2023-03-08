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
    end
  end
end

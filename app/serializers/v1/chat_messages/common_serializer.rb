module V1
  module ChatMessages
    class CommonSerializer < GenericSerializer
      attributes :id,
       :content,
       :user,
       :created_at,
       :read
    end
  end
end

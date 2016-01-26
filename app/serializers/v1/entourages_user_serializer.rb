module V1
  class EntouragesUserSerializer < ActiveModel::Serializer
    attributes :id,
               :email,
               :first_name,
               :last_name

    def id
      object.user.id
    end

    def email
      object.user.email
    end

    def first_name
      object.user.first_name
    end

    def last_name
      object.user.last_name
    end
  end
end

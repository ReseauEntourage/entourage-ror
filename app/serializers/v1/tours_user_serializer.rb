module V1
  class ToursUserSerializer < ActiveModel::Serializer
    attributes :id,
               :email,
               :first_name,
               :last_name,
               :status,
               :requested_at

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

    def requested_at
      object.created_at
    end
  end
end

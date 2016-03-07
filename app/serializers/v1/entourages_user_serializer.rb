module V1
  class EntouragesUserSerializer < ActiveModel::Serializer
    attributes :id,
               :email,
               :display_name

    def id
      object.user.id
    end

    def email
      object.user.email
    end

    def display_name
      "#{object.user.first_name} #{object.user.last_name}" if [object.user.first_name, object.user.last_name].compact.present?
    end
  end
end

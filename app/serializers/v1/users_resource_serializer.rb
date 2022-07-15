module V1
  class UsersResourceSerializer < ActiveModel::Serializer
    attributes :user_id,
      :resource_id,
      :watched
  end
end

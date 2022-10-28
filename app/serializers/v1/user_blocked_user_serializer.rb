module V1
  class UserBlockedUserSerializer < ActiveModel::Serializer
    attributes :status

    has_one :user, serializer: ::V1::Users::BasicSerializer
    has_one :blocked_user, serializer: ::V1::Users::BasicSerializer
  end
end

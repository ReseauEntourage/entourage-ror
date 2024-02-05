module V1
  class UserReactionSerializer < ActiveModel::Serializer
    attributes :reaction_id

    has_one :user, serializer: ::V1::Users::BasicSerializer
  end
end

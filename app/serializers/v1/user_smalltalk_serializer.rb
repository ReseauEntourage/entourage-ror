module V1
  class UserSmalltalkSerializer < ActiveModel::Serializer
    attributes :id,
      :uuid_v2,
      :smalltalk_id,
      :match_format,
      :match_locality,
      :match_gender,
      :match_interest,
      :last_match_computation_at,
      :matched_at,
      :deleted_at,
      :created_at

    has_one :user, serializer: ::V1::Users::BasicSerializer
    has_one :smalltalk, serializer: ::V1::SmalltalkSerializer
  end
end

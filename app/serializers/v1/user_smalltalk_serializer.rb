module V1
  class UserSmalltalkSerializer < ActiveModel::Serializer
    attributes :id,
      :uuid_v2,
      :smalltalk_id,
      :user_gender,
      :user_profile,
      :user_latitude,
      :user_longitude,
      :match_format,
      :match_locality,
      :match_gender,
      :match_interest,
      :last_match_computation_at,
      :matched_at,
      :deleted_at,
      :created_at
  end
end

module V1
  class UserSmalltalkSerializer < ActiveModel::Serializer
    attributes :id,
      :uuid_v2,
      :smalltalk_id,
      :match_format,
      :match_locality,
      :match_gender,
      :has_matched_format,
      :has_matched_gender,
      :has_matched_locality,
      :has_matched_interest,
      :number_of_unread_messages,
      :unmatch_count,
      :matched_at,
      :deleted_at,
      :created_at

    has_one :user, serializer: ::V1::Users::BasicSerializer
    has_one :smalltalk, serializer: ::V1::SmalltalkSerializer

    def number_of_unread_messages
      return unless object.smalltalk_id.present?
      return unless object.join_request

      object.join_request.unread_messages_count
    end
  end
end

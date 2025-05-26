module V1
  module Smalltalks
    class MatchesSerializer < ActiveModel::Serializer
      attributes :user_smalltalk_id,
        :smalltalk_id,
        :users,
        :has_matched_format,
        :has_matched_gender,
        :has_matched_locality,
        :has_matched_interest,
        :has_matched_profile,
        :unmatch_count

      def users
        object.users.map do |user|
          ::V1::Users::BasicSerializer.new(user, scope: scope).as_json
        end
      rescue
        []
      end

      def smalltalk_id
        smalltalk.id
      end
    end
  end
end

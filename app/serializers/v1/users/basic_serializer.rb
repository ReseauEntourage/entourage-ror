module V1
  module Users
    class BasicSerializer < ActiveModel::Serializer
      attributes :id, :display_name, :avatar_url, :community_roles

      def avatar_url
        UserServices::Avatar.new(user: object).thumbnail_url
      end

      def display_name
        UserPresenter.new(user: object).display_name
      end

      def community_roles
        UserPresenter.new(user: object).targeting_profiles
      end
    end
  end
end

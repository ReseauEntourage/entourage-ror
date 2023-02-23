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
        object.roles.sort_by { |r| object.community.roles.index(r) }.map do |role|
          I18n.t("community.entourage.roles.#{role}")
        end
      end
    end
  end
end

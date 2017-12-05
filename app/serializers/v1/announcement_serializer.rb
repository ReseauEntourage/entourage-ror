module V1
  class AnnouncementSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :body,
               :action,
               :url,
               :icon_url

    has_one :author

    def author
      return unless object.author
      author = object.author
      avatar_url = url_for(:avatar, id: object.id)
      {
          id: author.id,
          display_name: author.first_name,
          avatar_url: UserServices::Avatar.new(user: author).thumbnail_url,
          partner: nil
      }
    end

    def url
      url_for(:redirect, id: object.id, token: scope[:user].token)
    end

    def icon_url
      url_for(:icon, id: object.id)
    end

    def url_for action, options={}
      Rails.application.routes.url_helpers.send(
        "#{action}_api_v1_announcement_url",
        options.reverse_merge(host: scope[:base_url])
      )
    end
  end
end

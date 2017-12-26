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
      case object.id
      when 4
        avatar_url = url_for(:avatar, id: object.id)
      else
        avatar_url = UserServices::Avatar.new(user: author).thumbnail_url
      end

      {
          id: author.id,
          display_name: author.first_name,
          avatar_url: avatar_url,
          partner: nil
      }
    end

    def url
      url = url_for(:redirect, id: object.id, token: scope[:user].token)
      url = "#{ENV['DEEPLINK_SCHEME']}://webview?url=#{url}" if object.webview
      url
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

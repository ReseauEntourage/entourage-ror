module V1
  class AnnouncementSerializer < ActiveModel::Serializer
    attributes :id,
               :uuid,
               :title,
               :body,
               :image_url,
               :action,
               :url,
               :icon_url

    has_one :author, serializer: ActiveModel::DefaultSerializer

    def uuid
      object.id.to_s
    end

    def author
      return unless object.author
      author = object.author
      case object.id
      when 3, 4, 5, 12
        avatar_url = url_for(:avatar, id: object.id)
      else
        avatar_url = UserServices::Avatar.new(user: author).thumbnail_url
      end

      {
          id: author.id,
          display_name: UserPresenter.new(user: object.author).display_name,
          avatar_url: avatar_url,
          partner: nil
      }
    end

    def url
      if object.url =~ /^#{ENV['DEEPLINK_SCHEME']}:\/\// || object.url =~ /^mailto:/
        url = object.url
      else
        url = url_for(:redirect, id: object.id, token: scope[:user].token)
        url = "#{ENV['DEEPLINK_SCHEME']}://webview?url=#{url}" if object.webview
      end
      url
    end

    def icon_url
      url_for(:icon, id: object.id)
    end

    def image_url
      return if object.image_url.nil? || object.image_url == false
      v = object.image_url if object.image_url.is_a?(String)
      url_for(:image, id: object.id, v: v)
    end

    def url_for action, options={}
      Rails.application.routes.url_helpers.send(
        "#{action}_api_v1_announcement_url",
        options.reverse_merge(host: scope[:base_url])
      )
    end
  end
end

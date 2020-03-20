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
      return nil
    end

    def url
      if object.url.starts_with?('entourage:')
        url = object.url
        if EnvironmentHelper.env != :production
          url.gsub!(/^entourage/, ENV['DEEPLINK_SCHEME'])
        end
      elsif object.url.starts_with?('mailto:')
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

    def url_for action, options={}
      Rails.application.routes.url_helpers.send(
        "#{action}_api_v1_announcement_url",
        options.reverse_merge(host: scope[:base_url])
      )
    end
  end
end

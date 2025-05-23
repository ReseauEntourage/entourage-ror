module V1
  class ChatMessageSerializer < ActiveModel::Serializer
    attributes :id,
               :uuid_v2,
               :content,
               :content_html,
               :content_translations,
               :content_translations_html,
               :user,
               :created_at,
               :message_type,
               :status

    attribute :metadata, if: :metadata?

    def content
      return "" if object.deleted?
      return "" if object.offensive?

      Mentionable.no_html(
        I18nSerializer.new(object, :content, lang).translation
      )
    end

    def content_html
      return if object.deleted?

      I18nSerializer.new(object, :content, lang).translation
    end

    def content_translations
      return Hash.new if object.deleted?
      return Hash.new unless translations = I18nSerializer.new(object, :content, lang).translations
      return Hash.new unless translations.present?

      Mentionable.none_html!(translations)
    end

    def content_translations_html
      return Hash.new if object.deleted?

      I18nSerializer.new(object, :content, lang).translations
    end

    def metadata?
      object.message_type.in?(['outing', 'status_update', 'share'])
    end

    def user
      partner = object.user.partner

      {
        id: object.user_id,
        avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
        display_name: display_name,
        partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: {}, root: false).as_json,
        partner_role_title: object.user.partner_role_title.presence,
        roles: UserPresenter.new(user: object.user).public_targeting_profiles
      }
    end

    def display_name
      UserPresenter.new(user: object.user).display_name
    end

    def metadata
      object.metadata.except(:$id)
    end

    private

    def lang
      return unless scope && scope[:user] && scope[:user].lang

      scope[:user].lang
    end
  end
end

module V1
  class OutingSerializer < ActiveModel::Serializer
    include V1::Entourages::Location

    attributes :id,
               :uuid,
               :uuid_v2,
               :status,
               :title,
               :title_translations,
               :description,
               :description_translations,
               :share_url,
               :image_url,
               :event_url,
               :author,
               :online,
               :metadata,
               :interests,
               :neighborhoods,
               :recurrency,
               :member,
               :members,
               :members_count,
               :confirmed_member,
               :confirmed_members_count, # use number_of_confirmed_people instead
               :created_at,
               :updated_at,
               :status_changed_at,
               :distance

    has_one :location

    def title
      I18nSerializer.new(object, :title, lang).translation
    end

    def title_translations
      I18nSerializer.new(object, :title, lang).translations
    end

    def description
      I18nSerializer.new(object, :description, lang).translation
    end

    def description_translations
      I18nSerializer.new(object, :description, lang).translations
    end

    def uuid
      object.uuid_v2
    end

    def author
      return unless object.user.present?

      partner = object.user.partner

      {
        id: object.user.id,
        display_name: UserPresenter.new(user: object.user).display_name,
        avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
        partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: { minimal: true }, root: false).as_json,
        partner_role_title: object.user.partner_role_title.presence,
        community_roles: UserPresenter.new(user: object.user).public_targeting_profiles
      }
    end

    def member
      return false unless scope && scope[:user]

      object.member_ids.include?(scope[:user].id)
    end

    def members
      # fake data: not really used in mobile app
      # but to assure retrocompatibility with former app versions, we need this method to be compatible with "members.size"
      # so we want this method to return an array of "members" elements
      Array.new([object.members_count, 99].min, { id: 1, lang: "fr", avatar_url: "n/a", display_name: "n/a" })
    end

    def confirmed_member
      return false unless scope && scope[:user]

      object.confirmed_member_ids.include?(scope[:user].id)
    end

    def metadata
      object.metadata_with_image_paths.except(:$id)
    end

    def interests
      # we use "Tag.interest_list &" to force ordering
      Tag.interest_list & object.interest_names
    end

    def neighborhoods
      object.neighborhoods.pluck(:id, :name).map do |id, name|
        {
          id: id,
          name: name,
        }
      end
    end

    def recurrency
      return unless object.recurrence.present?

      object.recurrence.recurrency
    end

    private

    def lang
      return unless scope && scope[:user] && scope[:user].lang

      scope[:user].lang
    end
  end
end

module V1
  class OutingSerializer < ActiveModel::Serializer
    include V1::Entourages::Location

    attributes :id,
               :uuid,
               :uuid_v2,
               :status,
               :title,
               :description,
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
               :members_count,
               :created_at,
               :updated_at,
               :status_changed_at,
               :distance

    has_many :members, serializer: ::V1::Users::BasicSerializer
    has_one :location

    def title
      return object.title unless lang && object.translation

      object.translation.with_lang(lang).title || object.title
    end

    def description
      return object.description unless lang && object.translation

      object.translation.with_lang(lang).description || object.description
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
        partner_role_title: object.user.partner_role_title.presence
      }
    end

    def member
      return false unless scope && scope[:user]

      object.members.include? scope[:user]
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

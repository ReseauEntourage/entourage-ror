module V1
  class InappNotificationSerializer < ActiveModel::Serializer
    attributes :id,
      :instance,
      :instance_id,
      :content,
      :completed_at,
      :created_at,
      :image_url

    def record
      return unless object.instance

      object.instance.to_s.classify.constantize.find(object.instance_id)
    end

    def image_url
      method = "image_url_for_#{object.instance}"
      return unless respond_to?(method)

      send(method, record)
    end

    def image_url_for_neighborhood neighborhood
      neighborhood.image_url
    end

    def image_url_for_outing outing
      outing.image_url || outing.outing_image_url
    end

    def image_url_for_contribution contribution
      return unless contribution.image_url.present?
      Contribution.url_for(contribution.image_url)
    end

    def image_url_solicitation
      nil
    end

    def image_url_for_user user
      UserServices::Avatar.new(user: user).thumbnail_url
    end
  end
end

module V1
  class InappNotificationSerializer < ActiveModel::Serializer
    attributes :id,
      :instance,
      :instance_id,
      :post_id,
      :content,
      :completed_at,
      :created_at,
      :image_url,
      :context

    def image_url
      return image_url_for_sender if object.sender && object.chat_message_on_create?
      return image_url_for_sender if object.sender && object.join_request?

      return unless object.instance
      return unless object.record

      method = "image_url_for_#{object.instance}"
      return unless respond_to?(method)

      send(method, object.record)
    end

    def image_url_for_neighborhood_post post
      return image_url_for_sender if object.sender_id.present?

      image_url_for_neighborhood(post.messageable)
    end

    def image_url_for_outing_post post
      return image_url_for_sender if object.sender_id.present?

      image_url_for_outing(post.messageable)
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

    def image_url_for_sender
      return unless object.sender

      UserServices::Avatar.new(user: object.sender).thumbnail_url
    end

    def context
      I18n.t("activerecord.attributes.inapp_notification.context_types.#{object.context}", default: object.context)
    end
  end
end

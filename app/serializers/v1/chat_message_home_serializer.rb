module V1
  class ChatMessageHomeSerializer < V1::ChatMessageSerializer
    attribute :post_id
    attribute :has_comments
    attribute :comments_count
    attribute :image_url
    attribute :read

    def post_id
      object.parent_id
    end

    def has_comments
      object.has_children?
    end

    def comments_count
      object.children.count
    end

    def image_url
      return unless object.image_url.present?

      ChatMessage.url_for(object.image_url)
    end

    def read
      return unless current_join_request
      return false unless current_join_request.last_message_read.present?

      object.created_at <= current_join_request.last_message_read
    end

    private

    def current_join_request
      scope[:current_join_request]
    end
  end
end

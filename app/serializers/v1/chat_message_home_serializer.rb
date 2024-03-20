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
      object.comments_count > 0
    end

    def image_url
      object.image_url_with_size :medium
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

module V1
  module Images
    class ChatMessageSerializer < ActiveModel::Serializer
      attributes :chat_message_id, :url

      def chat_message_id
        object.id
      end

      def url
        object.preload_image_url || object.image_url_with_size(:high)
      end
    end
  end
end

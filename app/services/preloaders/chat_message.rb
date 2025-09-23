module Preloaders
  module ChatMessage
    def self.preload_images chat_messages, scope: nil
      chat_messages = chat_messages.to_a
      return if chat_messages.empty?

      images = ImageResizeAction
        .select("path, destination_path")
        .with_bucket_and_path(::ChatMessage.bucket_name, chat_messages.map(&:image_url).compact.uniq)
        .merge(scope || ImageResizeAction.all)
        .index_by { |image| image.path }

      chat_messages.each do |chat_message|
        next unless image = images[chat_message.image_url]
        next unless path = image.destination_path

        chat_message.preload_image_url = ::ChatMessage.image_url_for(path)
      end
    end
  end
end

class ChatMessageUploader < S3ImageUploader
  def self.metadata_keys
    [:chat_message_id]
  end

  def self.generate_s3_path params, extension
    "#{ChatMessage::BUCKET_PREFIX}/#{params[:chat_message_id]}-#{Time.now.to_i}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(authorized_params params)
    raise if payload.nil?

    chat_message = ChatMessage.find(payload[:chat_message_id])
    chat_message.update_column(:image_url, params[:key].gsub("chat_messages/", ""))

    chat_message
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:chat_message_id)
    ).to_h
  end

  def self.storage
    ChatMessage.bucket
  end
end

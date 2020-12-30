class EntourageImageUploader < S3ImageUploader
  def self.metadata_keys
    [:entourage_id]
  end

  def self.generate_s3_path params, extension
    "entourages/images/#{params[:entourage_id]}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(params)
    raise if payload.nil?

    entourage = Entourage.find(payload[:entourage_id])
    entourage.update_column(:image_url, payload[:object_url])

    entourage
  end
end

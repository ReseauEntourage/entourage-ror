class EntourageImageLandscapeUploader < S3ImageUploader
  def self.metadata_keys
    [:entourage_image_id]
  end

  def self.generate_s3_path params, extension
    "entourage_images/images/#{params[:entourage_image_id]}-landscape-#{Time.now.to_i}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(authorized_params params)
    raise if payload.nil?

    entourage_image = EntourageImage.find(payload[:entourage_image_id])
    entourage_image.update_column(:landscape_url, payload[:object_url])

    entourage_image
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:entourage_image_id)
    ).to_h
  end
end

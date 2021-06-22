class EntourageImagePortraitUploader < S3ImageUploader
  THUMBNAIL_RATIO = "40%"

  def self.metadata_keys
    [:entourage_image_id]
  end

  def self.generate_s3_path params, extension
    "entourage_images/images/#{params[:entourage_image_id]}-portrait-#{Time.now.to_i}.#{extension}"
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
    entourage_image.update_column(:portrait_url, payload[:object_url])
    entourage_image.update_column(:portrait_thumbnail_url, self.upload_thumbnail(payload[:object_url]))

    entourage_image
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:entourage_image_id)
    ).to_h
  end

  def self.filename_from_s3_path path
    path.gsub /(.)*entourage_images\/images\//, ''
  end

  def self.upload_thumbnail path
    object = Storage::Client.avatars.object("entourage_images/images/thumbnail-#{self.filename_from_s3_path path}")
    object.upload_file(self.resized_image(path, THUMBNAIL_RATIO))
    object.public_url
  end
end

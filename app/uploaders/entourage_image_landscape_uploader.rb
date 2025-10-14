class EntourageImageLandscapeUploader < S3ImageUploader
  THUMBNAIL_RATIO = '40%'

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
    entourage_image.update_column(:landscape_url, params[:key])
    entourage_image.update_column(:landscape_thumbnail_url, self.upload_thumbnail(payload[:object_url]))

    entourage_image
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:entourage_image_id)
    ).to_h
  end

  def self.generate_s3_thumbnail_path_from source_path
    "entourage_images/images/thumbnail-#{self.filename_from_s3_path source_path}"
  end

  # extract filename from a s3 fullpath
  def self.filename_from_s3_path path
    path.gsub /(.)*entourage_images\/images\//, ''
  end

  def self.upload_thumbnail source_path
    path = self.generate_s3_thumbnail_path_from source_path

    object = self.storage.object path
    object.upload_file(self.resized_image(source_path, THUMBNAIL_RATIO))

    path
  end

  def self.storage
    Storage::Client.images
  end
end

class ResourceImageUploader < S3ImageUploader
  def self.metadata_keys
    [:resource_image_id]
  end

  def self.generate_s3_path params, extension
    "resources/#{params[:resource_image_id]}-#{Time.now.to_i}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(authorized_params params)
    raise if payload.nil?

    resource_image = ResourceImage.find(payload[:resource_image_id])
    resource_image.update_column(:image_url, params[:key])

    resource_image
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:resource_image_id)
    ).to_h
  end

  def self.storage
    ResourceImage.storage
  end
end

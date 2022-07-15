class NeighborhoodImageUploader < S3ImageUploader
  def self.metadata_keys
    [:neighborhood_image_id]
  end

  def self.generate_s3_path params, extension
    "neighborhoods/#{params[:neighborhood_image_id]}-#{Time.now.to_i}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(authorized_params params)
    raise if payload.nil?

    neighborhood_image = NeighborhoodImage.find(payload[:neighborhood_image_id])
    neighborhood_image.update_column(:image_url, params[:key])

    neighborhood_image
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:neighborhood_image_id)
    ).to_h
  end

  def self.storage
    NeighborhoodImage.storage
  end
end

class RecommandationImageUploader < S3ImageUploader
  def self.metadata_keys
    [:recommandation_image_id]
  end

  def self.generate_s3_path params, extension
    "recommandations/#{params[:recommandation_image_id]}-#{Time.now.to_i}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(authorized_params params)
    raise if payload.nil?

    recommandation_image = RecommandationImage.find(payload[:recommandation_image_id])
    recommandation_image.update_column(:image_url, params[:key])

    recommandation_image
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:recommandation_image_id)
    ).to_h
  end

  def self.storage
    RecommandationImage.storage
  end
end

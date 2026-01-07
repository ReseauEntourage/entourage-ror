class PartnerUploader < S3ImageUploader
  def self.metadata_keys
    [:partner_id]
  end

  def self.generate_s3_path params, extension
    "#{Partner.bucket_prefix}/#{params[:partner_id]}-#{Time.now.to_i}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(authorized_params params)
    raise if payload.nil?

    partner = Partner.find(payload[:partner_id])
    partner.update_column(:image_url, params[:key].gsub("#{Partner.bucket_prefix}/", ''))

    partner
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:partner_id)
    ).to_h
  end

  def self.storage
    Partner.bucket
  end
end

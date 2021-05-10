class AnnouncementImageUploader < S3ImageUploader
  def self.metadata_keys
    [:announcement_id]
  end

  def self.generate_s3_path params, extension
    "announcements/images/#{params[:announcement_id]}-#{Time.now.to_i}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(authorized_params params)
    raise if payload.nil?

    announcement = Announcement.find(payload[:announcement_id])
    announcement.update_column(:image_url, payload[:object_url])

    announcement
  end

  private

  def self.authorized_params(params)
    params.permit(
      S3ImageUploader::AUTHORIZED_PARAMS.push(:announcement_id)
    ).to_h
  end
end

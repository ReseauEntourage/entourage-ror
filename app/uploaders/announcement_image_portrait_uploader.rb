class AnnouncementImagePortraitUploader < S3ImageUploader
  def self.metadata_keys
    [:announcement_id]
  end

  def self.generate_s3_path params, extension
    "announcements/images/#{params[:announcement_id]}-portrait-#{Time.now.to_i}.#{extension}"
  end

  def self.upload_options
    {
      acl: 'public-read',
    }
  end

  def self.handle_success params
    payload = self.payload(params)
    raise if payload.nil?

    announcement = Announcement.find(payload[:announcement_id])
    announcement.update_column(:image_portrait_url, payload[:object_url])

    announcement
  end
end
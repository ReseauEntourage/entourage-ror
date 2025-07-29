class UpdateAnnouncementsImagesPaths < ActiveRecord::Migration[5.1]
  def up
    Announcement.all.each do |announcement|
      ['image_url', 'image_portrait_url'].each do |field|
        if announcement[field].present? && announcement[field].include?('http')
          announcement.update_attribute(field,
            "announcements/images/#{announcement[field].gsub /(.)*announcements\/images\//, ''}"
          )
        end
      end
    end
  end

  def down
    Announcement.all.each do |announcement|
      ['image_url', 'image_portrait_url'].each do |field|
        unless announcement[field].blank? || announcement[field].include?('https://')
          announcement.update_attribute(field,
            "https://#{ENV['ENTOURAGE_AVATARS_BUCKET']}.s3.eu-west-1.amazonaws.com/#{announcement[field]}"
          )
        end
      end
    end
  end
end



class UpdateEntourageImagesPaths < ActiveRecord::Migration[5.1]
  def up
    EntourageImage.all.each do |entourage_image|
      ['landscape_thumbnail_url', 'landscape_url', 'portrait_thumbnail_url', 'portrait_url'].each do |field|
        if entourage_image[field].present? && entourage_image[field].include?(ENV['ENTOURAGE_AVATARS_BUCKET'])
          entourage_image.update_attribute(field,
            "entourage_images/images/#{entourage_image[field].gsub /(.)*entourage_images\/images\//, ''}"
          )
        end
      end
    end
  end

  def down
    EntourageImage.all.each do |entourage_image|
      ['landscape_thumbnail_url', 'landscape_url', 'portrait_thumbnail_url', 'portrait_url'].each do |field|
        unless entourage_image[field].blank? || entourage_image[field].include?('https://')
          entourage_image.update_attribute(field,
            "https://#{ENV['ENTOURAGE_AVATARS_BUCKET']}.s3.eu-west-1.amazonaws.com/#{entourage_image[field]}"
          )
        end
      end
    end
  end
end



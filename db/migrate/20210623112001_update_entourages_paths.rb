class UpdateEntouragesPaths < ActiveRecord::Migration[5.1]
  def up
    Entourage.where(group_type: :outing).where("metadata->>'landscape_url' like '%#{ENV['ENTOURAGE_AVATARS_BUCKET']}%'").each do |entourage|
      [:landscape_thumbnail_url, :landscape_url, :portrait_thumbnail_url, :portrait_url].each do |field|
        if entourage.metadata[field] && entourage.metadata[field].include?(ENV['ENTOURAGE_AVATARS_BUCKET'])
          entourage.metadata[field] = "entourage_images/images/#{entourage.metadata[field].gsub /(.)*entourage_images\/images\//, ''}"
          entourage.save
        end
      end
    end
  end

  def down
    Entourage.where(group_type: :outing).where("metadata->>'landscape_url' is not null").each do |entourage|
      [:landscape_thumbnail_url, :landscape_url, :portrait_thumbnail_url, :portrait_url].each do |field|
        unless entourage.metadata[field].blank? || entourage.metadata[field].include?('https://')
          entourage.metadata[field] = "https://#{ENV['ENTOURAGE_AVATARS_BUCKET']}.s3.eu-west-1.amazonaws.com/#{entourage.metadata[field]}"
          entourage.save
        end
      end
    end
  end
end



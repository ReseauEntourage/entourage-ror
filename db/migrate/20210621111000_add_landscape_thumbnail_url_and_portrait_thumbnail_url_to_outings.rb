class AddLandscapeThumbnailUrlAndPortraitThumbnailUrlToOutings < ActiveRecord::Migration[4.2]
  def up
    Entourage.where(group_type: :outing).each do |outing|
      outing.metadata[:landscape_thumbnail_url] = nil
      outing.metadata[:portrait_thumbnail_url] = nil
      outing.save(validate: false)
    end
  end

  def down
    Entourage.where(group_type: :outing).each do |outing|
      outing.metadata.delete(:landscape_thumbnail_url)
      outing.metadata.delete(:portrait_thumbnail_url)
      outing.save(validate: false)
    end
  end
end

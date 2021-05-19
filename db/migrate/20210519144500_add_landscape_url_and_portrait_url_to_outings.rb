class AddLandscapeUrlAndPortraitUrlToOutings < ActiveRecord::Migration[4.2]
  def up
    Entourage.where(group_type: :outing).each do |outing|
      outing.metadata[:landscape_url] = nil
      outing.metadata[:portrait_url] = nil
      outing.save(validate: false)
    end
  end

  def down
    Entourage.where(group_type: :outing).each do |outing|
      outing.metadata.delete(:landscape_url)
      outing.metadata.delete(:portrait_url)
      outing.save(validate: false)
    end
  end
end

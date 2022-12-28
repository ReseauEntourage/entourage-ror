class ComputeEntourageDenormHasImageUrl < ActiveRecord::Migration[5.2]
  def up
    return if EnvironmentHelper.test?

    ChatMessage.where(messageable_type: :Entourage)
      .select('messageable_id')
      .where('image_url is not null')
      .group(:messageable_id)
      .pluck(:messageable_id).each do |entourage_id|
        next unless entourage_denorm = EntourageDenorm.find_by_entourage_id(entourage_id)

        entourage_denorm.update_attribute(:has_image_url, true)
      end
  end

  def down
  end
end


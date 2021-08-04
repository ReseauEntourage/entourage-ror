class UpdateOutingMetadataWithPreviousAtDefault < ActiveRecord::Migration[5.1]
  def up
    Entourage.where(group_type: :outing).where("not(metadata ? 'previous_at')").each do |outing|
      outing.metadata[:previous_at] = nil
      outing.save(validate: false)
    end
  end

  def down
  end
end

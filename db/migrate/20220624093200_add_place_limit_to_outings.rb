class AddPlaceLimitToOutings < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      update entourages set metadata = jsonb_set(metadata, '{place_limit}', 'null', true) where group_type = 'outing';
    SQL
  end

  def down
    execute <<-SQL
      update entourages set metadata = metadata #-'{place_limit}' where group_type = 'outing';
    SQL
  end
end

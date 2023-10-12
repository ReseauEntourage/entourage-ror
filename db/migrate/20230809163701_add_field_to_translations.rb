class AddFieldToTranslations < ActiveRecord::Migration[6.1]
  def up
    add_column :translations, :instance_field, :string, default: :content

    execute <<-SQL
      update translations set instance_field = 'title' where instance_type = 'Entourage';
      update translations set instance_field = 'name' where instance_type = 'Neighborhood';
    SQL
  end

  def down
    remove_column :translations, :instance_field, :string, default: :content
  end
end


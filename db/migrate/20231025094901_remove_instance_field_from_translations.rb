class RemoveInstanceFieldFromTranslations < ActiveRecord::Migration[6.1]
  def up
    remove_column :translations, :instance_field
  end

  def down
    add_column :translations, :instance_field, :string, default: :content
  end
end

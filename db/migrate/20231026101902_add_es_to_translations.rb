class AddEsToTranslations < ActiveRecord::Migration[6.1]
  def change
    add_column :translations, :es, :jsonb, default: {}, null: false
  end
end


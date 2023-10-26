class AddFromLangToTranslations < ActiveRecord::Migration[6.1]
  def change
    add_column :translations, :from_lang, :string, default: :fr, null: false
  end
end


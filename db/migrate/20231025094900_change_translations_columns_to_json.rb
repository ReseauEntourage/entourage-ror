class ChangeTranslationsColumnsToJson < ActiveRecord::Migration[6.1]
  def up
    # change_column is refused by postgresql from string to jsonb
    # we do not care about data migration since translations are not in production at this point
    remove_column  :translations, :fr
    add_column :translations, :fr, :jsonb, default: {}, null: false

    remove_column  :translations, :en
    add_column :translations, :en, :jsonb, default: {}, null: false

    remove_column  :translations, :de
    add_column :translations, :de, :jsonb, default: {}, null: false

    remove_column  :translations, :pl
    add_column :translations, :pl, :jsonb, default: {}, null: false

    remove_column  :translations, :ro
    add_column :translations, :ro, :jsonb, default: {}, null: false

    remove_column  :translations, :uk
    add_column :translations, :uk, :jsonb, default: {}, null: false

    remove_column  :translations, :ar
    add_column :translations, :ar, :jsonb, default: {}, null: false
  end

  def down
    change_column :translations, :fr, :string
    change_column :translations, :en, :string
    change_column :translations, :de, :string
    change_column :translations, :pl, :string
    change_column :translations, :ro, :string
    change_column :translations, :uk, :string
    change_column :translations, :ar, :string
  end
end

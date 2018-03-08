class CreateSensitiveWordsChecks < ActiveRecord::Migration
  def change
    create_table :sensitive_words_checks do |t|
      t.string :status, null: false
      t.references :record, polymorphic: true, null: false, index: { unique: true }
      t.text :matches, null: false

      t.timestamps null: false
    end
  end
end

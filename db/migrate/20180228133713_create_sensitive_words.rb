class CreateSensitiveWords < ActiveRecord::Migration
  def change
    create_table :sensitive_words do |t|
      t.string :raw, null: false
      t.string :pattern, null: false
      t.string :match_type, null: false, default: :stem
      t.string :scope, null: false, default: :all
      t.string :category
    end
    add_index :sensitive_words, :pattern, unique: true
  end
end

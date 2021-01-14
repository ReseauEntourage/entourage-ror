class CreateMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :messages do |t|
      t.string :content, null: false

      t.timestamps null: false
    end
  end
end

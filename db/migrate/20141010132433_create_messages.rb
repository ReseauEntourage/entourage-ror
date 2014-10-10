class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.date :date
      t.string :content
      t.belongs_to :user
      t.belongs_to :group
      t.boolean :is_private
      t.timestamps
    end
  end
end

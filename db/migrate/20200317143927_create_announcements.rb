class CreateAnnouncements < ActiveRecord::Migration
  def change
    create_table :announcements do |t|
      t.string  :title
      t.string  :body
      t.string  :image_url
      t.string  :action
      t.string  :url
      t.string  :icon
      t.boolean :webview
      t.integer :position
      t.string  :status, default: 'draft', null: false
    end
  end
end

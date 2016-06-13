class AddMarketingRefererToUsers < ActiveRecord::Migration
  def change
    create_table :marketing_referers do |t|
      t.string :name,   null: false
      t.timestamps      null: false
    end

    add_column :users, :marketing_referer_id, :integer, null: false, default: 1
  end
end

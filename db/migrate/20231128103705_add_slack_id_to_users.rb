class AddSlackIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :slack_id, :string, null: true
  end
end

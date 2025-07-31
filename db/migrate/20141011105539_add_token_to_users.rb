class AddTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:users, :device_type)
      add_column :users, :device_type, :integer
    end

    add_column :users, :token, :string
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          user.set_token
        end
      end
    end
  end
end

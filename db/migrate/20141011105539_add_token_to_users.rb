class AddTokenToUsers < ActiveRecord::Migration
  def change
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

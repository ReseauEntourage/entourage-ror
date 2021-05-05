class AddSmsCodeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :sms_code, :string
  end
end

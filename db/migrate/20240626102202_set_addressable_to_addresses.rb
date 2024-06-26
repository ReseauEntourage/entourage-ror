class SetAddressableToAddresses < ActiveRecord::Migration[6.1]
  def change
    sql = <<-SQL
      UPDATE addresses
      SET addressable_id = user_id, addressable_type = 'User'
      WHERE user_id is not null
    SQL

    execute(sql)
  end
end

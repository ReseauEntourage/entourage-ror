class ChangeBirthdayLimitInUsers < ActiveRecord::Migration[5.2]
  def up
    change_column :users, :birthday, :string, limit: 10, nullable: true, default: nil
    rename_column :users, :birthday, :birthdate

    # manual execution due to timeout
    # execute <<-SQL
    #   update users set birthdate = null;
    # SQL
  end
end

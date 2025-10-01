class ChangeBirthdayToBirthdateInLocalUsers < ActiveRecord::Migration[6.1]
  # change birthday to birthdate
  def up
    return unless ActiveRecord::Base.connection.schema_exists?('stats')

    sql = <<-SQL
      CREATE OR REPLACE VIEW stats.local_users
      AS SELECT 
        users.id,
        users.uuid,
        users.email,
        users.first_name,
        users.last_name,
        users.phone,
        users.birthdate,
        users.created_at,
        users.updated_at,
        users.deleted,
        users.validation_status,
        users.interests_old,
        users.other_interest,
        users.availability,
        users.targeting_profile,
        addresses.postal_code
      FROM users
      left join addresses on addresses.id = users.address_id
    SQL

    execute(sql)
  end

  def down
    return unless ActiveRecord::Base.connection.schema_exists?('stats')

    sql = <<-SQL
      CREATE OR REPLACE VIEW stats.local_users
      AS SELECT 
        users.id,
        users.uuid,
        users.email,
        users.first_name,
        users.last_name,
        users.phone,
        users.birthday,
        users.created_at,
        users.updated_at,
        users.deleted,
        users.validation_status,
        users.interests_old,
        users.other_interest,
        users.availability,
        users.targeting_profile,
        addresses.postal_code
      FROM users
      left join addresses on addresses.id = users.address_id
    SQL

    execute(sql)
  end
end

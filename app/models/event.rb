class Event < ApplicationRecord
  belongs_to :user

  INSERT_SQL = 'insert into events (name, user_id, created_at) values (%s, %s, %s) on conflict do nothing'.freeze

  def self.track name, user_id:, at: Time.now
    connection.execute(
      INSERT_SQL % [name, user_id, at].map { |v| connection.quote(v) }
    ).clear
  rescue ActiveRecord::StatementInvalid => e
    raise e
  rescue => e
    Rails.logger.error(e)
  end

  def self.names
    connection.execute('select unnest(enum_range(null::event_name))').column_values(0)
  end
end

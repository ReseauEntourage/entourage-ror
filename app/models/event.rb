class Event < ApplicationRecord
  belongs_to :user

  INSERT_SQL = <<~SQL.freeze
    INSERT INTO events (name, user_id, created_at)
    VALUES (%s, %s, %s)
    ON CONFLICT DO NOTHING
  SQL

  def self.track name, user_id:, at: Time.now
    return unless user_id.present?
    return unless valid_event_name?(name)

    connection.execute(
      INSERT_SQL % [name, user_id, at].map { |v| connection.quote(v) }
    ).clear
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.warn(e.message)
  rescue => e
    Sentry.capture_exception(e)
  end

  # enum
  def self.valid_event_names
    @valid_event_names ||= connection.select_values(<<~SQL)
      SELECT unnest(enum_range(NULL::event_name))
    SQL
  end

  def self.valid_event_name?(name)
    valid_event_names.include?(name)
  end

  def self.reset_event_names_cache!
    @valid_event_names = nil
  end

  def self.names
    valid_event_names
  end
end

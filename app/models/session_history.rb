class SessionHistory < ApplicationRecord
  belongs_to :user

  INSERT_SQL = 'insert into session_histories (user_id, platform, date) values (%s, %s, %s) on conflict do nothing'.freeze
  UPSERT_NOTIFICATIONS_PERMISSIONS_SQL = %(
    insert into session_histories (user_id, platform, date, notifications_permissions) values (%s, %s, %s, %s)
    on conflict (user_id, platform, date) do update set notifications_permissions = excluded.notifications_permissions
  ).freeze

  def self.enable_tracking?
    !Rails.env.test?
  end

  def self.track user_id:, platform:, date: Time.zone.today
    return unless enable_tracking? && platform.present?
    connection.execute(
      INSERT_SQL % [user_id, platform, date].map { |v| connection.quote(v) }
    ).clear
  end

  def self.track_notifications_permissions user_id:, platform:, notifications_permissions:, date: Time.zone.today
    return unless enable_tracking? && platform.present? && notifications_permissions.present?
    connection.execute(
      UPSERT_NOTIFICATIONS_PERMISSIONS_SQL % [user_id, platform, date, notifications_permissions].map { |v| connection.quote(v) }
    ).clear
  end
end

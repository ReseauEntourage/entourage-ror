class SessionHistory < ActiveRecord::Base
  belongs_to :user

  INSERT_SQL = "insert into session_histories (user_id, platform, date) values (%s, %s, %s) on conflict do nothing".freeze

  def self.enable_tracking?
    !Rails.env.test?
  end

  def self.track user_id:, platform:, date: Time.zone.today
    return unless enable_tracking?
    connection.execute(
      INSERT_SQL % [user_id, platform, date].map { |v| connection.quote(v) }
    ).clear
  end
end

class FeatureSwitch
  attr_reader :user

  def initialize user
    @user = user
  end

  def variant test
    self.send test, user
  end

  def feed user
    if user.id.in? env_feed_v2_users
      :v2
    elsif user.id % 2 == 0
      :v2
    else
      :v1
    end
  end

  def env_feed_v2_users
    @env_feed_users ||=
      (ENV['FEED_V2_USERS'] || "")
      .split(',')
      .map { |s| Integer(s) rescue nil }
      .compact
      .uniq
  end
end

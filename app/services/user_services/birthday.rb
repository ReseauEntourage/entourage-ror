module UserServices
  class Birthday
    def self.send_notifications
      users.find_each do |user|
        PushNotificationTrigger.new(user, :birthday, Hash.new).notify
      end
    end

    def self.users
      User
        .validated
        .where.not(birthdate: nil)
        .where.not(birthdate: '')
        .where("last_sign_in_at >= NOW() - INTERVAL '1 year'")
        .where("right(birthdate, 5) = ?", Time.zone.today.strftime("%m-%d"))
    end
  end
end

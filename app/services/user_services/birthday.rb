module UserServices
  class Birthday
    def self.send_notifications
      User
        .validated
        .where.not(birthdate: nil)
        .where.not(birthdate: '')
        .where("last_sign_in_at >= NOW() - INTERVAL '1 year'")
        .where("to_char(birthdate, 'MM-DD') = ?", Time.zone.today.strftime("%m-%d"))
        .pluck(:id)
        .find_each do |user|
        PushNotificationTrigger.new(user, :birthday, Hash.new).notify
      end
    end
  end
end

module TestingServices
  class Notifications
    attr_accessor :user, :method_name

    def initialize user, method_name
      @user = user
      @method_name = method_name
    end

    def run
      raise "Bad method_name request" unless respond_to?(method_name)
      raise "User should be super_admin" unless user.super_admin?

      send(method_name)
    end

    def user_smalltalk_on_almost_match
      records = user.user_smalltalks

      send_notification(records.last, :almost_match)
    end

    def user_reaction_on_create
      records = UserReaction
        .where.not(user: user)
        .where(instance_type: :ChatMessage)
        .where("instance_id in (select id from chat_messages where user_id = ?)", user.id)

      send_notification(records.last, :create)
    end

    def ios_with_rpush
      raise 'no ios app' unless ios_app
      raise 'user does not have ios token' unless ios_token

      TestingServices::Rpushs.new(ios_app, ios_token).ios_push
    end

    def ios_without_rpush
      raise 'no ios app' unless ios_app
      raise 'user does not have ios token' unless ios_token

      TestingServices::RpushFreeIos.new(ios_app, ios_token).push
    end

    def android_with_rpush
      raise 'no android app' unless android_app
      raise 'user does not have android token' unless android_token

      TestingServices::Rpushs.new(android_app, android_token).android_push
    end

    def android_without_rpush
      raise 'no android app' unless android_app
      raise 'user does not have android token' unless android_token

      TestingServices::RpushFreeAndroid.new(android_app, android_token).push
    end

    private

    def send_notification record, verb
      raise 'Current user does not have any record of this method_name' unless record

      notification_trigger = PushNotificationTrigger.new(record, verb, Hash.new)

      raise 'Notification has not be sent' unless notification_trigger.run
    end

    def ios_token
      @ios_token ||= find_token(UserApplication::IOS)
    end

    def android_token
      @android_token ||= find_token(UserApplication::ANDROID)
    end

    def find_token family
      user.user_applications
        .where(device_family: family)
        .order('updated_at DESC')
        .pick(:push_token)
    end

    def ios_app
      @ios_app ||= Rpush::Apnsp8::App.order(created_at: :desc).first
    end

    def android_app
      @android_app ||= Rpush::Fcm::App.order(created_at: :desc).first
    end
  end
end

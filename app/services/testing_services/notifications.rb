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

    def send_notification record, verb
      raise 'Current user does not have any record of this method_name' unless record

      notification_trigger = PushNotificationTrigger.new(record, verb, Hash.new)

      raise 'Notification has not be sent' unless notification_trigger.run
    end
  end
end

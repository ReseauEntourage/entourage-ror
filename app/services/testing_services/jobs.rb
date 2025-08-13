module TestingServices
  class Jobs
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

    def push_notification_trigger_job
      PushNotificationTriggerJob.perform_later("User", :create, @user.id, { "first_name" => @user.first_name })
    end

    def notification_job
      PushNotificationService.new.send_notification(:sender, :object, :content, [@user], 'user', @user.id, { foo: :bar })
    end
  end
end

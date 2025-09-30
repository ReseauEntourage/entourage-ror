module TestingServices
  class Emails
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

    def weekly_planning
      action_ids = Action.order(created_at: :desc).limit(3).pluck(:id)
      outing_ids = Outing.order(created_at: :desc).limit(3).pluck(:id)

      MemberMailer.weekly_planning(user, action_ids, outing_ids).deliver_later
    end

    def event_participation_reminder
      outing = Outing.order(created_at: :desc).first

      GroupMailer.event_participation_reminder(outing, user).deliver_later
    end
  end
end

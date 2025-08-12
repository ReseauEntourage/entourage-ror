module TestingServices
  class Salesforce
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

    def outing_sync
      raise 'Current user does not have any record of this method_name' unless outing

      outing.sync_salesforce(true)
    end

    def outing
      outing ||= Outing
        .where(salesforce_id: nil)
        .where(online: false)
        .where(user: User.where(targeting_profile: ['team', 'ambassador']))
        .last
    end
  end
end

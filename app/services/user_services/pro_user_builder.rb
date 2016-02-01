module UserServices
  class ProUserBuilder < UserServices::UserBuilder
    def initialize(params:, organization: nil)
      @organization = organization
      super(params: params)
    end

    def new_user(sms_code=nil)
      user = organization.users.new(params)
      user.user_type = 'pro'
      user.token = token
      user.sms_code = sms_code || UserServices::SmsCode.new.code
      user
    end

    def update(user:)
      snap_to_road = (params.delete(:snap_to_road) == "true")
      simplified_tour = (params.delete(:simplified_tour) == "true")
      PreferenceServices::UserDefault.new(user: user).snap_to_road = snap_to_road
      PreferenceServices::UserDefault.new(user: user).simplified_tour = simplified_tour
      user.update_attributes(params)
    end

    private
    attr_reader :organization
  end
end
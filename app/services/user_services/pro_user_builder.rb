module UserServices
  class ProUserBuilder < UserServices::UserBuilder
    def initialize(params:, organization: nil)
      @organization = organization
      super(params: params)
    end

    def new_or_upgraded_user
      if existing_user
        set_pro(existing_user)
      else
        new_user
      end
    end

    def new_user(sms_code=nil)
      user = User.new(params)
      user.token = token
      user.sms_code = sms_code || UserServices::SmsCode.new.code
      user.community = 'entourage'
      set_pro(user)
      user
    end

    def create_or_upgrade(*args, &block)
      if existing_user
        upgrade_to_pro(user: existing_user, &block)
      else
        create(*args, &block)
      end
    end

    def update(user:)
      simplified_tour = (params.delete(:simplified_tour) == "true")
      PreferenceServices::UserDefault.new(user: user).simplified_tour = simplified_tour
      user.update(params)
    end

    def upgrade_to_pro(user:)
      yield callback if block_given?

      set_pro(user)

      if user.save
        callback.on_success.try(:call, user)
      else
        callback.on_failure.try(:call, user)
      end

      user
    end

    private
    attr_reader :organization

    def set_pro(user)
      [:first_name, :last_name, :email].each do |attribute|
        user[attribute] ||= params[attribute]
      end
      user.manager = params.key?(:manager) ? params[:manager] : false
      user.user_type = 'pro'
      # TODO: what if already member/manager of another org?
      user.organization = organization
      user
    end

    def existing_user
      return @existing_user if defined?(@existing_user)
      formatted_phone = User.new(params.slice(:phone)).phone
      @existing_user = User.find_by(phone: formatted_phone)
    end
  end
end

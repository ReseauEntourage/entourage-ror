module UserServices
  class PublicUserBuilder < UserBuilder
    def initialize(params:, community:)
      @community = community
      super(params: params)
    end

    def new_user(sms_code=nil)
      user = User.new(params)
      user.user_type = 'public'
      user.community = community.slug
      user.token = token
      user.sms_code = sms_code || UserServices::SmsCode.new.code
      user.roles =
        case user.community
        when 'pfp'
          [:not_validated]
        else
          []
        end
      user
    end

    def update(user:, platform: nil)
      yield callback if block_given?

      return callback.on_failure.try(:call, user) if params.keys.include?(:phone)

      if params.key?(:sms_code) && platform != :mobile
        return callback.on_failure.try(:call, user)
      end

      avatar_file = params.delete(:avatar)
      if avatar_file
        UserServices::Avatar.new(user: user).upload(file: avatar_file)
      end

      start_onboarding_sequence = should_start_onboarding_sequence(user: user, params: params)
      user.onboarding_sequence_start_at = Time.zone.now if start_onboarding_sequence

      [:first_name, :last_name, :email].each do |key|
        params[key] = params[key]&.strip if params.key?(key)
      end

      if user.update(params)
        signal_blocked_user(user)
        signal_association(user)

        callback.on_success.try(:call, user)
      else
        callback.on_failure.try(:call, user)
      end
    end

    private
    attr_reader :community

    def should_start_onboarding_sequence(user:, params:)
      user.onboarding_sequence_start_at.nil? &&
      params[:email] && user.email.nil? &&
      user.first_sign_in_at && user.first_sign_in_at >= 1.week.ago
    end
  end
end

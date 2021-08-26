module UserServices
  class RequestPhoneChange
    USERNAME = 'Changement de téléphone'

    def initialize(user:)
      @user = user
    end

    def request(requested_phone:, email:)
      record_phone_request! requested_phone, email

      SlackServices::RequestPhoneChange.new(user: @user, requested_phone: requested_phone, email: email).notify
    end

    private

    def record_phone_request! requested_phone, email
      UserPhoneChange.create(
        user_id: @user.id,
        kind: :request,
        phone_was: @user.phone,
        phone: requested_phone,
        email: email
      )
    end

    def self.record_phone_change! user:, admin:
      UserPhoneChange.create(
        user_id: user.id,
        admin_id: admin.id,
        kind: :change,
        phone_was: user.phone_was,
        phone: user.phone,
        email: user.email
      )
    end

    def self.cancel_phone_change! user:, admin:
      UserPhoneChange.create(
        user_id: user.id,
        admin_id: admin.id,
        kind: :cancel,
        phone_was: user.phone,
        phone: user.phone,
        email: user.email
      )
    end
  end
end

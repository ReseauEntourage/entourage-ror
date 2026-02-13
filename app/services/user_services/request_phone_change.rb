module UserServices
  class RequestPhoneChange
    USERNAME = 'Changement de téléphone'

    def initialize user:
      @user = user
    end

    def request requested_phone:
      request = request_record(requested_phone)

      return unless request.new_record?

      request.save!

      SlackServices::RequestPhoneChange.new(user: @user, requested_phone: requested_phone).notify
    end

    def self.record_phone_change! user:, admin:
      UserPhoneChange.create(
        user_id: user.id,
        admin_id: admin.id,
        kind: :change,
        previous_phone: user.phone_was,
        phone: user.phone
      )
    end

    def self.cancel_phone_change! user:, admin:
      UserPhoneChange.create(
        user_id: user.id,
        admin_id: admin.id,
        kind: :cancel,
        previous_phone: user.phone,
        phone: user.phone
      )
    end

    private

    def request_record requested_phone
      UserPhoneChange.find_or_initialize_by(
        user_id: @user.id,
        kind: :request,
        previous_phone: @user.phone,
        phone: requested_phone
      )
    end
  end
end

module UserServices
  class History
    attr_accessor :user

    ACCOUNT_CREATION = 'Création du compte'

    def initialize user
      @user = user
    end

    def get
      elements.map do |element|
        method_name = "history_from_#{element.class.table_name}"

        return history_undefined_method(element) unless respond_to?(method_name, true)

        send method_name, element
      end.sort do |element_a, element_b|
        element_a[:date] <=> element_b[:date]
      end
    end

    def elements
      [user] + user.user_histories + sms_deliveries_history(user) + user.user_phone_changes
    end

    protected

    def sms_deliveries_history user
      SmsDelivery.where(phone_number: user.phone)
    end

    def history_undefined_method element
      {
        kind: element.class.table_name,
        date: element&.created_at,
        moderator: nil,
        metadata: "method #{method_name} not found"
      }
    end

    def history_from_users user
      {
        kind: :account,
        date: user.created_at,
        moderator: nil,
        metadata: ACCOUNT_CREATION
      }
    end

    def history_from_sms_deliveries sms_delivery
      {
        kind: :sms,
        date: sms_delivery.created_at,
        moderator: nil,
        metadata: I18n.t("activerecord.attributes.user_history.sms.#{sms_delivery.sms_type}")
      }
    end

    def history_from_user_phone_changes user_phone_change
      {
        kind: "phone_change_#{user_phone_change.kind.to_sym}",
        date: user_phone_change.created_at,
        moderator: user_phone_change.admin,
        metadata: nil
      }
    end

    def history_from_user_histories user_history
      {
        kind: user_history.kind.to_sym,
        date: user_history.created_at,
        moderator: user_history.updater,
        metadata: user_history.message || user_history.cnil_explanation
      }
    end
  end
end

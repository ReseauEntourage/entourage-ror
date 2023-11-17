module NewsletterServices
  class Contact
    MAILJET_LIST_ID = "2822632"

    attr_reader :callback, :email, :zone, :status, :active

    def initialize params:
      @callback = Callback.new

      @email = params[:email]
      @zone = params[:zone]
      @status = params[:status]
      @active = params[:active]
    end

    def create
      yield callback if block_given?

      return callback.on_failure.try(:call) unless create_or_update_in_db
      return callback.on_failure.try(:call) unless create_or_update_in_mailjet

      callback.on_success.try(:call)
    end

    private

    def create_or_update_in_db
      newsletter_subscription = NewsletterSubscription.find_or_initialize_by(email: email)
      newsletter_subscription.assign_attributes(
        zone: zone,
        status: status,
        active: active
      )
      newsletter_subscription.save!
    end

    def create_or_update_in_mailjet
      Mailjet::Contactslist_managecontact.create(
        id: MAILJET_LIST_ID,
        properties: {
          newsletter_entourage: true,
          antenne_entourage: zone,
          profil_entourage: status
        },
        action: "addnoforce",
        email: email
      )
    end
  end
end

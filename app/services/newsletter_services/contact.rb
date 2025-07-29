module NewsletterServices
  class Contact
    MAILJET_LIST_ID = '2822632'
    STATUS = {
      particulier: 'PARTICULIER',
      association: 'ASSOCIATION',
      entreprise: 'ENTREPRISE'
    }
    ZONES = {
      bordeaux: { name: 'BORDEAUX', departments: ['33'] },
      lorient: { name: 'LORIENT', departments: ['56'] },
      marseille: { name: 'MARSEILLE', departments: ['13'] },
      nantes: { name: 'NANTES', departments: ['44'] },
      paris: { name: 'PARIS', departments: ['75', '92', '93', '94', '95'] },
      lyon: { name: 'LYON', departments: ['69'] },
      lille: { name: 'LILLE', departments: ['59', '62'] },
      rennes: { name: 'RENNES', departments: ['35'] },
      saint_malo: { name: 'SAINT-MALO', departments: ['35'] },
      hors_zone: { name: 'HORS ZONE', departments: ['00'] }
    }

    attr_reader :callback, :email, :zone, :status, :active

    def initialize params
      @callback = Callback.new

      @email = params[:email]
      @zone = params[:zone]
      @status = params[:status]
      @active = params[:active]
    end

    def show
      yield callback if block_given?

      return callback.on_failure.try(:call) unless list_recipient = get_list_recipient

      callback.on_success.try(:call, list_recipient)
    end

    def create
      yield callback if block_given?

      return callback.on_failure.try(:call) unless create_or_update_in_db
      return callback.on_failure.try(:call) unless create_or_update_in_mailjet

      callback.on_success.try(:call)
    end

    def delete
      yield callback if block_given?

      return callback.on_failure.try(:call) unless delete_in_db
      return callback.on_failure.try(:call) unless delete_in_mailjet

      callback.on_success.try(:call)
    end

    class << self
      def zone_for_address address
        return ZONES[:hors_zone][:name] unless address

        ZONES.each do |zone, params|
          return params[:name] if params[:departments].include?(address.departement)
        end

        ZONES[:hors_zone][:name]
      end

      def status_for_user user
        return STATUS[:association] if user.admin? || user.moderator? || user.association?

        STATUS[:particulier]
      end
    end

    private

    def get_contact
      return unless contact = Mailjet::Contact.find(email)

      contact.attributes
    end

    def get_list_recipient
      return unless contact = get_contact
      return unless list_recipient = Mailjet::Listrecipient.first(Contact: contact['id'], ContactsList: MAILJET_LIST_ID)

      list_recipient.attributes
    end

    def create_or_update_in_db
      newsletter_subscription = NewsletterSubscription.find_or_initialize_by(email: email)
      newsletter_subscription.assign_attributes(
        zone: zone,
        status: status,
        active: active || true
      )
      newsletter_subscription.save
    end

    def delete_in_db
      return unless newsletter_subscription = NewsletterSubscription.find_by(email: email)

      newsletter_subscription.update_attribute(:active, false)
    end

    def create_or_update_in_mailjet
      Mailjet::Contactslist_managecontact.create(
        id: MAILJET_LIST_ID,
        properties: {
          newsletter_entourage: true,
          antenne_entourage: zone,
          profil_entourage: status
        },
        action: 'addnoforce',
        email: email
      )
    end

    def delete_in_mailjet
      return unless list_recipient = get_list_recipient

      Mailjet::Listrecipient.find(list_recipient['id']).delete
    end
  end
end

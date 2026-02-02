module SalesforceServices
  class ContactTableInterface < TableInterface
    TABLE_NAME = 'Contact'

    INSTANCE_MAPPING = {
      first_name: 'FirstName',
      last_name: 'LastName',
      email: 'Email',
      phone: 'Phone',
      record_type_id: 'RecordTypeId',
      antenne: 'Antenne__c',
      reseau: 'Reseaux__c',
      casquette: 'Casquettes_r_les__c',
      postal_code: 'MailingPostalCode',
      gender: 'Genre__c',
      birthdate: 'Birthdate',
      birthdate_copy: 'Date_de_naissance__c',
      sourcing: 'Comment_nous_avez_vous_connu__c',
    }

    CASQUETTES_MAPPING = {
      ambassador: 'ENT Ambassadeur',
      default: "ENT User de l'app",
    }

    GENDER_MAPPING = {
      "female" => "Femme",
      "male" => "Homme",
      "secret" => "Secret",
    }

    SOURCING_MAPPING = {
      "panel" => "Affichage (panneaux, métro)",
      "newspaper" => "Un article dans la presse, une newsletter",
      "word_of_mouth" => "Le bouche à oreille",
      "association" => "Association / travailleur social",
      "entreprise" => "Mon entreprise",
      "television" => "Télévision / radio",
      "social" => "Autres réseaux (facebook, twitter, instagram...)",
      "social_event" => "Evénement salon",
    }

    def initialize instance:
      super(table_name: TABLE_NAME, instance: instance)
    end

    def external_id_key
      :phone
    end

    def external_id_value
      'ID_externe__c'
    end

    def mapping
      @mapping ||= MappingStruct.new(contact: instance)
    end

    def instance_mapping
      INSTANCE_MAPPING
    end

    MappingStruct = Struct.new(:contact) do
      attr_accessor :contact

      def initialize(contact: nil)
        @contact = contact
      end

      def method_missing(method_name, *args, &block)
        if contact.respond_to?(method_name)
          contact.public_send(method_name, *args, &block)
        else
          raise NoMethodError, "Undefined method `#{method_name}` for #{self.class.name} and #{contact.class.name}"
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        contact.respond_to?(method_name, include_private) || super
      end

      # id
      def id
        contact.id
      end

      def external_id
        contact.id
      end

      # fields
      def first_name
        contact.first_name
      end

      def last_name
        contact.last_name
      end

      def email
        contact.email
      end

      def phone
        contact.phone
      end

      def record_type_id
        return unless record_type = SalesforceServices::RecordType.find_for_user(contact)

        record_type.salesforce_id
      end

      def antenne
        contact.sf.from_address_to_antenne
      end

      def reseau
        'Entourage'
      end

      def casquette
        contact.ambassador? ? CASQUETTES_MAPPING[:ambassador] : CASQUETTES_MAPPING[:default]
      end

      def postal_code
        contact.postal_code
      end

      def gender
        return unless GENDER_MAPPING.has_key?(contact.gender)

        GENDER_MAPPING[contact.gender]
      end

      # hack one hour to avoid timezone issues on salesforce
      def birthdate
        (contact.birthdate + 1.hour).strftime('%Y-%m-%d')
      end

      # hack one hour to avoid timezone issues on salesforce
      def birthdate_copy
        (contact.birthdate + 1.hour).strftime('%Y-%m-%d')
      end

      def sourcing
        return unless user.sourcing.present?
        return unless SOURCING_MAPPING.has_key?(key = user.sourcing.to_sym)

        SOURCING_MAPPING[key]
      end
    end
  end
end

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
    }

    CASQUETTES_MAPPING = {
      ambassador: 'ENT Ambassadeur',
      default: "ENT User de l'app",
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
    end
  end
end

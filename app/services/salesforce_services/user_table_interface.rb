module SalesforceServices
  class UserTableInterface < TableInterface
    TABLE_NAME = 'Compte_App__c'

    INSTANCE_MAPPING = {
      first_name: 'Prenom__c',
      last_name: 'Nom__c',
      email: 'Email__c',
      phone: 'Telephone__c',
      profil_declare: 'ProfilDeclare__c',
      profil_moderation: 'ProfilModeration__c',
      antenne: 'Antenne__c',
      postal_code: 'Code_postal__c',
      latitude: 'Geolocalisation__Latitude__s',
      longitude: 'Geolocalisation__Longitude__s',
      created_date: 'DateCreationCompte__c',
      last_sign_in_date: 'DateDerniereConnexion__c',
      last_engagement_date: 'LastEngagementDate__c',
      is_engaged: 'IsEngaged__c',
      status: 'Status__c'
    }

    GOAL_MAPPING = {
      ask_for_help: 'preca',
      offer_help: 'riverain',
      organization: 'asso',
      default: 'inconnu'
    }
    TARGETING_PROFILE_MAPPING = {
      asks_for_help: 'preca',
      offers_help: 'riverain',
      partner: 'asso',
      team: 'asso',
      ambassador: 'riverain',
      default: 'inconnu'
    }
    DELETED_MAPPING = {
      true => 'supprimé',
      false => 'actif'
    }

    def initialize instance:
      super(table_name: TABLE_NAME, instance: instance)
    end

    def external_id_key
      :id
    end

    def external_id_value
      'UserId__c'
    end

    def mapping
      @mapping ||= MappingStruct.new(user: instance)
    end

    def instance_mapping
      INSTANCE_MAPPING
    end

    MappingStruct = Struct.new(:user) do
      attr_accessor :user

      def initialize(user: nil)
        @user = user
      end

      def method_missing(method_name, *args, &block)
        if user.respond_to?(method_name)
          user.public_send(method_name, *args, &block)
        else
          raise NoMethodError, "Undefined method `#{method_name}` for #{self.class.name} and #{user.class.name}"
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        user.respond_to?(method_name, include_private) || super
      end

      def id
        user.id
      end

      def external_id
        user.id
      end

      def first_name
        user.first_name
      end

      def last_name
        user.last_name
      end

      def email
        user.email
      end

      def phone
        user.phone
      end

      def profil_declare
        return GOAL_MAPPING[:default] unless user.goal.present?
        return GOAL_MAPPING[user.goal.to_sym] if GOAL_MAPPING[user.goal.to_sym]

        GOAL_MAPPING[:default]
      end

      def profil_moderation
        return TARGETING_PROFILE_MAPPING[:default] unless user.targeting_profile.present?
        return TARGETING_PROFILE_MAPPING[user.targeting_profile.to_sym] if TARGETING_PROFILE_MAPPING[user.targeting_profile.to_sym]

        TARGETING_PROFILE_MAPPING[:default]
      end

      def antenne
        user.sf.from_address_to_antenne
      end

      def postal_code
        user.postal_code
      end

      def latitude
        user.latitude
      end

      def longitude
        user.longitude
      end

      def created_date
        user.created_at.strftime('%Y-%m-%d')
      end

      def last_sign_in_date
        return unless user.last_sign_in_at.present?

        user.last_sign_in_at.strftime('%Y-%m-%d')
      end

      def last_engagement_date
        return unless denorm_daily_engagement = user.denorm_daily_engagements.order(id: :desc).first

        denorm_daily_engagement.date.strftime('%Y-%m-%d')
      end

      def is_engaged
        user.denorm_daily_engagements.any?
      end

      def status
        DELETED_MAPPING[user.deleted]
      end
    end
  end
end

module SalesforceServices
  class OutingTableInterface < TableInterface
    TABLE_NAME = 'Campaign'

    INSTANCE_MAPPING = {
      id: 'Id_app_de_l_event__c',
      address: 'Adresse_de_l_v_nement__c',
      antenne: 'Antenne__c',
      title: 'Name',
      postal_code: 'Code_postal__c',
      starts_date: 'StartDate',
      starts_time: 'Heure_de_d_but__c',
      ends_date: 'EndDate',
      ends_time: 'Heure_de_fin__c',
      ongoing?: 'IsActive',
      sf_status: 'Status',
      status: 'Statut_d_Entourage__c',
      reseau: 'R_seaux__c',
      record_type_id: 'RecordTypeId',
      type: 'Type',
      type_public: 'Public_sensibilis__c',
      type_evenement: 'Type_evenement__c'
    }

    def initialize instance:
      super(table_name: TABLE_NAME, instance: instance)
    end

    def external_id_key
      :id
    end

    def external_id_value
      'OutingId__c'
    end

    def mapping
      @mapping ||= MappingStruct.new(outing: instance)
    end

    def instance_mapping
      INSTANCE_MAPPING
    end

    MappingStruct = Struct.new(:outing) do
      attr_accessor :outing

      def initialize(outing: nil)
        @outing = outing
      end

      def method_missing(method_name, *args, &block)
        if outing.respond_to?(method_name)
          outing.public_send(method_name, *args, &block)
        else
          raise NoMethodError, "Undefined method `#{method_name}` for #{self.class.name} and #{outing.class.name}"
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        outing.respond_to?(method_name, include_private) || super
      end

      def id
        outing.id
      end

      def external_id
        outing.id
      end

      def address
        outing.address
      end

      def antenne
        outing.sf.from_address_to_antenne
      end

      # this method ensures that salesforce title will be 80 caracters max
      # with city: at least 30 caracters
      # with title: at least 30 caracters
      # with starts_date: no truncation
      def title
        slashes = ' // '
        dot = ' - '

        truncate_priority(
          [outing.city, slashes, remove_emojis(outing.title), dot, starts_date.to_s],
          max_length: 80,
          min_lengths: [30, slashes.length, 30, dot.length, starts_date.to_s.length]
        )
      end

      def postal_code
        outing.postal_code
      end

      # hack one hour to avoid timezone issues on salesforce
      def starts_date
        return unless outing.starts_at.present?

        (outing.starts_at + 1.hour).strftime('%Y-%m-%d')
      end

      # hack one hour to avoid timezone issues on salesforce
      def starts_time
        return unless outing.starts_at.present?

        (outing.starts_at + 1.hour).strftime('%H:%M:%S')
      end

      # hack one hour to avoid timezone issues on salesforce
      def ends_date
        return unless outing.ends_at.present?

        (outing.ends_at + 1.hour).strftime('%Y-%m-%d')
      end

      # hack one hour to avoid timezone issues on salesforce
      def ends_time
        return unless outing.ends_at.present?

        (outing.ends_at + 1.hour).strftime('%H:%M:%S')
      end

      def ongoing?
        outing.ongoing?
      end

      def sf_status
        'Aborted' unless outing.ongoing?

        'Planned'
      end

      def status
        # only outings created by staff or ambassadors are sync with salesforce
        'Organisateur'
      end

      def reseau
        'Entourage'
      end

      def record_type_id
        return unless record_type = SalesforceServices::RecordType.find_for_outing

        record_type.salesforce_id
      end

      def type
        'Event'
      end

      def type_public
        'Grand public'
      end

      def type_evenement
        'Evenement de convivialité'
      end

      # private

      def truncate_priority(parts, max_length:, min_lengths:)
        str = parts.join
        parts.each_with_index do |part, i|
          while str.length > max_length && part.length > min_lengths[i]
            parts[i] = part = part.truncate(min_lengths[i])
            str = parts.join
          end
        end
        str
      end

      def remove_emojis str
        str.scan(/\X/).reject { |cluster|
          cluster.match?(/[\p{Extended_Pictographic}\p{Regional_Indicator}\uFE0F]/u)
        }.join.strip
      end
    end
  end
end

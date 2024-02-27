module Populate
  class << self
    def set_resources
      load_resources_config.each do |key, attributes|
        Resource.new(attributes).save
      end
    end

    def set_recommandations
      load_recommandations_config.each do |key, attributes|
        recommandation = Recommandation.new(attributes)

        if recommandation.resource? && recommandation.show?
          recommandation.argument_value = find_resource_id(recommandation.argument_value)
        end

        recommandation.save
      end
    end

    def set_salesforce_configs
      SalesforceServices::RecordType.new.import
    end

    def delete_resources
      Resource.delete_all
    end

    def delete_recommandations
      Recommandation.delete_all
    end

    def delete_salesforce_configs
      SalesforceConfig.delete_all
    end

    def load_config type
      YAML.load_file("#{Rails.root}/config/populates/#{type}.yml")
    end

    def load_resources_config
      @resources_config ||= load_config(:resources)
    end

    def load_recommandations_config
      @recommandations_config ||= load_config(:recommandations)
    end

    def find_resource_id identifiant
      return unless resource_hash = load_resources_config[identifiant]
      return unless resource = Resource.find_by_name(resource_hash["name"])

      resource.id
    end
  end
end

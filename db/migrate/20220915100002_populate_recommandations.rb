class PopulateRecommandations < ActiveRecord::Migration[5.2]
  def up
    return if EnvironmentHelper.test?

    load_config.each do |key, attributes|
      recommandation = Recommandation.new(attributes)

      if recommandation.resource? && recommandation.show?
        recommandation.argument_value = find_resource_id(recommandation.argument_value)
      end

      recommandation.save
    end
  end

  def down
    Recommandation.delete_all
  end

  private

  def load_config
    YAML.load_file("#{Rails.root}/config/populates/recommandations.yml")
  end

  def find_resource_id identifiant
    return unless resource_hash = load_resources_config[identifiant]
    return unless resource = Resource.find_by_name(resource_hash["name"])

    resource.id
  end

  def load_resources_config
    @resources_config ||= YAML.load_file("#{Rails.root}/config/populates/resources.yml")
  end
end


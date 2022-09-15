class PopulateResources < ActiveRecord::Migration[5.2]
  def up
    return if EnvironmentHelper.test?

    load_config.each do |key, attributes|
      Resource.new(attributes).save
    end
  end

  def down
    Resource.delete_all
  end

  private

  def load_config
    YAML.load_file("#{Rails.root}/config/populates/resources.yml")
  end
end


require 'tasks/populate'

namespace :populate do
  desc 'Generates resources based on config/populates/resources.yml'
  task set_resources: :environment do
    Populate.set_resources
  end

  desc 'delete all resources'
  task delete_resources: :environment do
    Populate.delete_resources
  end

  desc 'Generates recommandations based on config/populates/recommandations.yml'
  task set_recommandations: :environment do
    Populate.set_recommandations
  end

  desc 'delete all recommandations'
  task delete_recommandations: :environment do
    Populate.delete_recommandations
  end

  desc 'Generate salesforce config for record_types'
  task set_salesforce_record_types: :environment do
    Populate.set_salesforce_record_types
  end

  desc 'Generate salesforce config for campaign parents'
  task set_salesforce_campaign_parents: :environment do
    Populate.set_salesforce_campaign_parents
  end
end

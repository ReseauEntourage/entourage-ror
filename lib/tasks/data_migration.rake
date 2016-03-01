namespace :data_migration do
  desc "set test organization"
  task set_test_organization: :environment do
    Organization.where(id: [1]).update_all(test_organization: true)
  end
end
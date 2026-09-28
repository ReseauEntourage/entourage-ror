require 'rails_helper'

# Every index action of app/controllers/api/v1 and app/controllers/admin must have its N+1 spec
# (@see spec/support/n_plus_one_helper.rb), under the same path in spec/n_plus_one, unless it
# is listed below with the reason why it cannot have one.
describe 'N+1 specs coverage' do
  def not_testable_indexes
    {
      'admin/salesforce/contacts' => 'Salesforce API data only',
      'admin/salesforce/outings' => 'Salesforce API data only',
      'admin/salesforce/sf_entreprises' => 'Salesforce API data only',
      'admin/salesforce/sf_entreprises/outings' => 'Salesforce API data only',
      'admin/salesforce/users' => 'Salesforce API data only',
      'api/v1/salesforce/sf_entreprises' => 'Salesforce API data only',
      'api/v1/salesforce/sf_entreprises/outings' => 'Salesforce API data only',
      'api/v1/public/stats' => 'three fixed counts, cached: not a list',
      'api/v1/notification_permissions' => 'a single record: not a list',
    }
  end

  def controllers_with_index
    Dir[Rails.root.join('app/controllers/{api/v1,admin}/**/*_controller.rb')]
      .select { |file| File.read(file).match?(/^\s*def index\b/) }
      .map { |file| file.delete_prefix(Rails.root.join('app/controllers/').to_s).delete_suffix('_controller.rb') }
      .sort
  end

  def n_plus_one_spec_exists? controller
    File.exist?(Rails.root.join("spec/n_plus_one/#{controller}_controller_spec.rb"))
  end

  it 'has an N+1 spec for every index action' do
    missing = controllers_with_index.reject { |controller| n_plus_one_spec_exists?(controller) || not_testable_indexes.key?(controller) }

    expect(missing).to be_empty, "Missing N+1 specs (spec/n_plus_one/<controller>_controller_spec.rb): #{missing.join(', ')}"
  end

  it 'only lists indexes that still exist and have no N+1 spec as not testable' do
    stale = not_testable_indexes.keys.reject { |controller| controllers_with_index.include?(controller) && !n_plus_one_spec_exists?(controller) }

    expect(stale).to be_empty, "Remove from not_testable_indexes: #{stale.join(', ')}"
  end
end

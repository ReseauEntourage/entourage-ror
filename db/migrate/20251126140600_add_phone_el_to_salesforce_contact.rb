class AddPhoneElToSalesforceContact < ActiveRecord::Migration[7.1]
  def up
    return unless EnvironmentHelper.production? || EnvironmentHelper.staging?

    SalesforceServices::TableInterface.create_field(
      'Contact',
      'Phone_EL',
      'Téléphone Entourage Local',
      'Phone'
    )
  end

  def down
    return unless EnvironmentHelper.production? || EnvironmentHelper.staging?

    SalesforceServices::TableInterface.delete_field('Contact', 'Phone_EL')
  end
end
